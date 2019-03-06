#include "libxmos.h"
#include <linux/i2c-dev.h>
#include <linux/i2c.h>
#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <iostream>

#define IS_CONTROL_CMD_READ(c) ((c) & 0x80)
#define I2C_TRANSACTION_MAX_BYTES 256
#define I2C_DATA_MAX_BYTES (I2C_TRANSACTION_MAX_BYTES - 3)

namespace
{
    size_t control_build_i2c_data(uint8_t data[I2C_TRANSACTION_MAX_BYTES],
                                  uint8_t resid, uint8_t cmd,
                                  const uint8_t payload[], size_t payload_len)
    {
        data[0] = resid;
        data[1] = cmd;
        data[2] = (uint8_t)payload_len;
        if (IS_CONTROL_CMD_READ(cmd)) {
            return 3;
        }      
        for (size_t i = 0; i < payload_len; i++) {
            data[3 + i] = payload[i];
        }
        return 3 + payload_len;
    }

    class I2C
    {
        uint8_t m_slave;
        int m_fd;
        bool m_initialized;
    public:
        I2C(uint8_t slave)
            : m_slave(slave)
            , m_fd(open("/dev/i2c-1", O_RDWR))
            , m_initialized(false)
        {
            if (m_fd < 0) {
                std::cerr << "failed to open i2c port error " << errno << std::endl;
                return;
            }
            if (ioctl(m_fd, I2C_SLAVE, m_slave) < 0) {
                std::cerr << "Unable to set i2c configuration at address:" << std::hex 
                        << m_slave << " errno:" << std::hex << errno << std::endl;
                return;
            }
            // This writes command zero to register zero. It is a workaround for RPI kernel 4.4 which seems to ignore the first data bytes otherwise
            // It is a benign operation for lib_device_control as register zero, command zero is the version and is read only
            uint8_t data[3] = { 0 };
            control_build_i2c_data(data, 0, 0, data, 0);
            ::write(m_fd, data, sizeof(data));
            m_initialized = true;
        }

        virtual ~I2C()
        {
            close(m_fd);
        }

        bool initialized() const { return m_initialized; }

        int read(uint8_t resid, uint8_t cmd, uint8_t * payload, size_t payload_len)
        {
            unsigned char read_hdr[I2C_TRANSACTION_MAX_BYTES];
            unsigned len = control_build_i2c_data(read_hdr, resid, cmd, payload, payload_len);
            if (len != 3){
                std::cerr << "Error building read command section of read_device. len should be 3 but is " << len << std::endl;
                return 1;
            }   
            struct i2c_msg rdwr_msgs[2] = {
                {   // Start address
                    .addr = m_slave,
                    .flags = 0, // write
                    .len = (unsigned short)len, //will be 3
                    .buf = read_hdr
                },
                {   // Read buffer
                    .addr = m_slave,
                    .flags = I2C_M_RD, // read
                    .len = (unsigned short)payload_len,
                    .buf = payload
                }
            };  
            struct i2c_rdwr_ioctl_data rdwr_data = {
                .msgs = rdwr_msgs, 
                .nmsgs = 2
            };
            if (ioctl(m_fd, I2C_RDWR, &rdwr_data) < 0) {
                std::cerr << "rdwr ioctl error " << errno << std::endl;
                return 1;
            }
            return 0;
        }

        int write(uint8_t resid, uint8_t cmd, const uint8_t payload[], size_t payload_len)
        {
            unsigned char buffer_to_send[I2C_TRANSACTION_MAX_BYTES + 3];
            int len = control_build_i2c_data(buffer_to_send, resid, cmd, payload, payload_len);
            int written = ::write(m_fd, buffer_to_send, len);
            if (written != len){
                std::cerr << "Error writing to i2c. " << written << " of " << len << " bytes sent" << std::endl;
                return 1;
            }
            return 0;
        }
    };
} // namespace

int get_angle(void)
{
    I2C i2c(0x2c);
    if(!i2c.initialized()){
        return -1;
    }
    uint8_t buf0[4] = { 0 };
    if(0 != i2c.read(0x12, 0xBE, buf0, sizeof(buf0))){
        return -1;
    }
    uint8_t buf1[8] = { 0 };
    if(0 != i2c.read(0x15, 0xC0, buf1, sizeof(buf1))){
        return -1;
    }
    return (buf1[1] << 8) + (buf1[0] & 0xFF);
}
