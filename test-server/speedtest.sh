speed_test() {
        local speedtest=$(wget -4O /dev/null -T300 --report-speed=bits $1 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}')
        local ipaddress=$(ping -c1 -n `awk -F'/' '{print $3}' <<< $1` | awk -F'[()]' '{print $2;exit}')
        local nodeName=$2
        printf "${YELLOW}%-40s${GREEN}%-16s${RED}%-14s${PLAIN}\n" "${nodeName}" "${ipaddress}" "${speedtest}"
}

speed() {
        speed_test 'http://cachefly.cachefly.net/100mb.test' 'CacheFly'
        speed_test 'https://lax-ca-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Los Angeles, CA'
        speed_test 'https://wa-us-ping.vultr.com/vultr.com.100MB.bin' 'Vultr, Seattle, WA'
        speed_test 'http://speedtest.tokyo.linode.com/100MB-tokyo.bin' 'Linode, Tokyo, JP'
        speed_test 'http://speedtest.singapore.linode.com/100MB-singapore.bin' 'Linode, Singapore, SG'
        speed_test 'http://speedtest.hkg02.softlayer.com/downloads/test100.zip' 'Softlayer, HongKong, CN'
        speed_test 'http://speedtest1.vtn.com.vn/speedtest/random4000x4000.jpg' 'VNPT, Ha Noi, VN'
        speed_test 'http://speedtest5.vtn.com.vn/speedtest/random4000x4000.jpg' 'VNPT, Da Nang, VN'
        speed_test 'http://speedtest3.vtn.com.vn/speedtest/random4000x4000.jpg' 'VNPT, Ho Chi Minh, VN'
        speed_test 'http://speedtestkv1a.viettel.vn/speedtest/random4000x4000.jpg' 'Viettel Network, Ha Noi, VN'
        speed_test 'http://speedtestkv2a.viettel.vn/speedtest/random4000x4000.jpg' 'Viettel Network, Da Nang, VN'
        speed_test 'http://speedtestkv3a.viettel.vn/speedtest/random4000x4000.jpg' 'Viettel Network, Ho Chi Minh, VN'
        speed_test 'http://speedtesthn.fpt.vn/speedtest/random4000x4000.jpg' 'FPT Telecom, Ha Noi, VN'
        speed_test 'http://speedtest.fpt.vn/speedtest/random4000x4000.jpg' 'FPT Telecom, Ho Chi Minh, VN'
        speed_test 'http://lg.chi2-c.fdcservers.net/100MBtest.zip' 'Chicago, fdcservers, US'
        speed_test 'http://lg.den2-c.fdcservers.net/100MBtest.zip' 'Denver, fdcservers, US'
        speed_test 'http://lg.la2-c.fdcservers.net/100MBtest.zip' 'LA, fdcservers, US'
        speed_test 'http://lg.mia-c.fdcservers.net/100MBtest.zip' 'Miami, fdcservers, US'
        speed_test 'http://lg.ny2-c.fdcservers.net/100MBtest.zip' 'NY, fdcservers, US'
        speed_test 'http://lg.sea-z.fdcservers.net/100MBtest.zip' 'SEA, fdcservers, US'
        speed_test 'http://lg-tor.fdcservers.net/100MBtest.zip' 'Toronto, fdcservers, CA'
}
tmp=$(mktemp)
speed | tee $tmp
