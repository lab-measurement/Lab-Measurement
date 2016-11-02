require '_h2ph_pre.ph';

no warnings qw(redefine misc);

unless(defined(&__LINUX_USB_TMC_H)) {
    eval 'sub __LINUX_USB_TMC_H () {1;}' unless defined(&__LINUX_USB_TMC_H);
    eval 'sub USBTMC_STATUS_SUCCESS () {0x1;}' unless defined(&USBTMC_STATUS_SUCCESS);
    eval 'sub USBTMC_STATUS_PENDING () {0x2;}' unless defined(&USBTMC_STATUS_PENDING);
    eval 'sub USBTMC_STATUS_FAILED () {0x80;}' unless defined(&USBTMC_STATUS_FAILED);
    eval 'sub USBTMC_STATUS_TRANSFER_NOT_IN_PROGRESS () {0x81;}' unless defined(&USBTMC_STATUS_TRANSFER_NOT_IN_PROGRESS);
    eval 'sub USBTMC_STATUS_SPLIT_NOT_IN_PROGRESS () {0x82;}' unless defined(&USBTMC_STATUS_SPLIT_NOT_IN_PROGRESS);
    eval 'sub USBTMC_STATUS_SPLIT_IN_PROGRESS () {0x83;}' unless defined(&USBTMC_STATUS_SPLIT_IN_PROGRESS);
    eval 'sub USBTMC_REQUEST_INITIATE_ABORT_BULK_OUT () {1;}' unless defined(&USBTMC_REQUEST_INITIATE_ABORT_BULK_OUT);
    eval 'sub USBTMC_REQUEST_CHECK_ABORT_BULK_OUT_STATUS () {2;}' unless defined(&USBTMC_REQUEST_CHECK_ABORT_BULK_OUT_STATUS);
    eval 'sub USBTMC_REQUEST_INITIATE_ABORT_BULK_IN () {3;}' unless defined(&USBTMC_REQUEST_INITIATE_ABORT_BULK_IN);
    eval 'sub USBTMC_REQUEST_CHECK_ABORT_BULK_IN_STATUS () {4;}' unless defined(&USBTMC_REQUEST_CHECK_ABORT_BULK_IN_STATUS);
    eval 'sub USBTMC_REQUEST_INITIATE_CLEAR () {5;}' unless defined(&USBTMC_REQUEST_INITIATE_CLEAR);
    eval 'sub USBTMC_REQUEST_CHECK_CLEAR_STATUS () {6;}' unless defined(&USBTMC_REQUEST_CHECK_CLEAR_STATUS);
    eval 'sub USBTMC_REQUEST_GET_CAPABILITIES () {7;}' unless defined(&USBTMC_REQUEST_GET_CAPABILITIES);
    eval 'sub USBTMC_REQUEST_INDICATOR_PULSE () {64;}' unless defined(&USBTMC_REQUEST_INDICATOR_PULSE);
    eval 'sub USBTMC_IOC_NR () {91;}' unless defined(&USBTMC_IOC_NR);
    eval 'sub USBTMC_IOCTL_INDICATOR_PULSE () { &_IO( &USBTMC_IOC_NR, 1);}' unless defined(&USBTMC_IOCTL_INDICATOR_PULSE);
    eval 'sub USBTMC_IOCTL_CLEAR () { &_IO( &USBTMC_IOC_NR, 2);}' unless defined(&USBTMC_IOCTL_CLEAR);
    eval 'sub USBTMC_IOCTL_ABORT_BULK_OUT () { &_IO( &USBTMC_IOC_NR, 3);}' unless defined(&USBTMC_IOCTL_ABORT_BULK_OUT);
    eval 'sub USBTMC_IOCTL_ABORT_BULK_IN () { &_IO( &USBTMC_IOC_NR, 4);}' unless defined(&USBTMC_IOCTL_ABORT_BULK_IN);
    eval 'sub USBTMC_IOCTL_CLEAR_OUT_HALT () { &_IO( &USBTMC_IOC_NR, 6);}' unless defined(&USBTMC_IOCTL_CLEAR_OUT_HALT);
    eval 'sub USBTMC_IOCTL_CLEAR_IN_HALT () { &_IO( &USBTMC_IOC_NR, 7);}' unless defined(&USBTMC_IOCTL_CLEAR_IN_HALT);
}
1;
