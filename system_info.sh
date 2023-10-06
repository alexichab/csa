#!/bin/bash


LANG=C

function Parameter() {
	local level=${1:-0}

	while [[ ${level} -gt 0 ]]; do
		printf "    "
		((level--))
	done

	printf "%s\n" "${2:-Unnamed parameter}: ${3:-?}${4}"
}

# Получаем текущую дату
current_date=$(date)

# Получаем имя пользователя
user_name=$(whoami)

# Получаем доменное имя ПК (hostname)
domain_name=$(hostname)

# Получаем информацию о процессоре
cpu_info=$(lscpu)
cpu_model=$(echo "$cpu_info" | grep "Model name" | awk -F: '{print $2}' | xargs)
cpu_architecture=$(echo "$cpu_info" | grep "Architecture" | awk -F: '{print $2}' | xargs)
cpu_max_freq=$(lscpu | grep "CPU max MHz" | awk -F: '{print $2}' | xargs)
cpu_curr_freq=$(cat /proc/cpuinfo | grep "MHz" ) 
cpu_cores=$(echo "$cpu_info" | grep "Core(s) per socket" | awk -F: '{print $2}' | xargs)
cpu_threads=$(echo "$cpu_info" | grep "Thread(s) per core" | awk -F: '{print $2}' | xargs)
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

# Получаем информацию о оперативной памяти
memory_info=$(free -h)
memory_l1=$(lscpu | grep "L1d cache" | awk -F: '{print $2}' | xargs)
memory_l2=$(lscpu | grep "L2 cache" | awk -F: '{print $2}' | xargs)
memory_l3=$(lscpu | grep "L3 cache" | awk -F: '{print $2}' | xargs)
memory_total=$(echo "$memory_info" | grep "Mem:" | awk '{print $2}')
memory_available=$(echo "$memory_info" | grep "Mem:" | awk '{print $7}')

# Получаем информацию о жестком диске
disk_info=$(df -h)
disk_total=$(echo "$disk_info" | grep "/$" | awk '{print $2}')
disk_available=$(echo "$disk_info" | grep "/$" | awk '{print $4}')
num_partitions=$(echo "$disk_info" | grep -c "^/dev/")

# Получаем информацию о каждом разделе
partition_info=$(df -h)
partition_list=$(df -h | grep "^/dev/")

# Получаем информацию о корневой директории
root_partition=$(df -h / | tail -1)
root_mounted=$(echo "$root_partition" | awk '{print $1}')
root_unallocated=$(parted -l | grep -A1 "^Model: " | tail -1 | awk '{print $3}')

# Получаем информацию о SWAP
swap_info=$(free -h | grep "Swap:")
swap_total=$(echo "$swap_info" | awk '{print $2}')
swap_available=$(echo "$swap_info" | awk '{print $3}')

# Получаем информацию о сетевых интерфейсах
network_interfaces=$(ip addr show)
num_interfaces=$(echo "$network_interfaces" | grep -c "^[0-9]:")

# Выводим полученные данные
echo "Дата: $current_date"
echo "Имя учетной записи: $user_name"
echo "Доменное имя ПК: $domain_name"
echo "Процессор:"
echo "Модель: $cpu_model"
echo "Архитектура: $cpu_architecture"
echo "Тактовая частота максимальная: $cpu_max_freq MHz"
echo "Тактовая частота текущая: "
echo "$cpu_curr_freq"
echo "Количество ядер: $cpu_cores"
echo "Количество потоков на одно ядро: $cpu_threads"
echo "Загрузка процессора: $cpu_usage%"
echo "Оперативная память:"
echo "Cache L1: $memory_l1"
echo "Cache L2: $memory_l2"
echo "Cache L3: $memory_l3"
echo "Всего: $memory_total"
echo "Доступно: $memory_available"
echo "Жесткий диск:"
echo "Всего: $disk_total"
echo "Доступно: $disk_available"
echo "Количество разделов: $num_partitions"

# Выводим информацию о каждом разделе
echo "Информация о разделах:"
echo "$partition_list"

# Выводим информацию о корневой директории
echo "Смонтировано в корневую директорию /: $root_mounted"
echo "Объём неразмеченного пространства: $root_unallocated"
echo "SWAP всего: $swap_total"
echo "SWAP доступно: $swap_available"

# Выводим информацию о сетевых интерфейсах
#echo "Сетевые интерфейсы:"
#echo "Количество сетевых интерфейсов: $num_interfaces"
#echo "$network_interfaces" | grep "^[0-9]:" | while read -r line
#do
#  interface_name=$(echo "$line" | awk '{print $2}' | rev | cut -c 2- | rev)
#  interface_mac=$(ip link show "$interface_name" | awk '/ether/ {print $2}')
#  interface_ip=$(echo "$line" | awk '/inet/ {print $2}')
#  interface_standard=$(ethtool "$interface_name" 2>/dev/null | grep "Supported link modes" | awk -F: '{print $2}' | xargs)
#  interface_max_speed=$(ethtool "$interface_name" 2>/dev/null | grep "Speed" | awk -F: '{print $2}' | xargs)
#  interface_actual_speed=$(ethtool "$interface_name" 2>/dev/null | grep "Duplex" | awk -F: '{print $2}' | xargs)
#  
#  echo "Интерфейс: $interface_name"
#  echo "MAC: $interface_mac"
#  echo "IP: $interface_ip"
#  echo "Стандарт связи: $interface_standard"
#  echo "Максимальная скорость соединения: $interface_max_speed"
#  echo "Фактическая скорость соединения: $interface_actual_speed"
#done

function Network() {
  echo "Сетевые интерфейсы:"
	Parameter 1 "Количество сетевых интерфейсов:" "$(ip -o link show | wc -l)"

	local has_ip=0

	for interface in /sys/class/net/*; do
		local name="$(basename "${interface}")"

		Parameter 1 "${name}" " "
		Parameter 2 MAC "$(cat "${interface}"/address)"

		Parameter 2 IP " "
		for ip in $(ip addr show "${name}" | grep -E '\<(inet)\>' | awk '{print $2}'); do
			Parameter 3 IPv4 "${ip}"
			has_ip=1
		done

		for ip in $(ip addr show "${name}" | grep -E '\<(inet6)\>' | awk '{print $2}'); do
			Parameter 3 IPv6 "${ip}"
			has_ip=1
		done

		if [ "${name}" != "lo" ] && [ -e "${interface}"/speed ]; then
			local speed="$(cat "${interface}"/speed 2>/dev/null)"
			if [[ ${speed} ]] && [[ ${speed} -ge 0 ]]; then
				Parameter 2 "Nominal speed" "${speed}" " Mbits/sec"
			fi
		fi

		if [[ ${has_ip} == 1 ]]; then
			local speed="$(curl --connect-timeout 3 --max-time 7 --fail-early http://cachefly.cachefly.net/10mb.test --interface "${name}" -w "%{speed_download}" -o /dev/null -s)"
			speed=$(echo "${speed}" | numfmt --to=iec-i)

			if [[ ${speed} ]]; then
				Parameter 2 "Actual speed" "${speed}" B/s
			fi
		fi

		if [ "${name}" != "lo" ] && [ -e "${interface}"/duplex ]; then
			local duplex="$(cat "${interface}"/duplex 2>/dev/null)"
			if [[ ${duplex} ]] && [[ ${duplex} != "unknown" ]]; then
				Parameter 2 Duplex "${duplex}"
			fi
		fi
	done
}

Network