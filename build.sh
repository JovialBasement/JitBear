#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

APP_NAME="privacy-ssh"
BUILD_DIR="dist"

go mod download
go mod tidy
go mod vendor


echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}   Privacy SSH Server Builder${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# ============================================
# COLLECT USER INPUT
# ============================================

echo -e "${GREEN}Configuration:${NC}"
echo ""

# Username
read -p "Enter username [default: secureuser]: " USERNAME
USERNAME=${USERNAME:-secureuser}

# Password
while true; do
    read -sp "Enter password (min 8 chars): " PASSWORD
    echo ""
    if [ ${#PASSWORD} -lt 8 ]; then
        echo -e "${RED}Password must be at least 8 characters!${NC}"
        continue
    fi
    read -sp "Confirm password: " PASSWORD_CONFIRM
    echo ""
    if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
        break
    else
        echo -e "${RED}Passwords don't match! Try again.${NC}"
    fi
done

# Port
read -p "Enter listen port [default: 2222]: " PORT
PORT=${PORT:-2222}

# Server version string
read -p "Enter SSH server version string [default: SSH-2.0-OpenSSH_8.9p1]: " SERVER_VERSION
SERVER_VERSION=${SERVER_VERSION:-SSH-2.0-OpenSSH_8.9p1}

echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  Username: $USERNAME"
echo "  Password: $(echo $PASSWORD | sed 's/./*/g')"
echo "  Port: $PORT"
echo "  Version: $SERVER_VERSION"
echo ""

read -p "Continue with these settings? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# ============================================
# ARCHITECTURE SELECTION
# ============================================

echo ""
echo -e "${GREEN}Select target architectures to build:${NC}"
echo ""

# Define all available architectures
declare -A ARCHS=(
    # Linux
    ["1"]="linux/amd64"
    ["2"]="linux/386"
    ["3"]="linux/arm/5"
    ["4"]="linux/arm/6"
    ["5"]="linux/arm/7"
    ["6"]="linux/arm64"
    ["7"]="linux/mips"
    ["8"]="linux/mipsle"
    ["9"]="linux/mips64"
    ["10"]="linux/mips64le"
    ["11"]="linux/ppc64"
    ["12"]="linux/ppc64le"
    ["13"]="linux/riscv64"
    ["14"]="linux/s390x"
    
    # macOS
    ["15"]="darwin/amd64"
    ["16"]="darwin/arm64"
    
    # Windows
    ["17"]="windows/amd64"
    ["18"]="windows/386"
    ["19"]="windows/arm64"
    
    # FreeBSD
    ["20"]="freebsd/amd64"
    ["21"]="freebsd/386"
    ["22"]="freebsd/arm"
    ["23"]="freebsd/arm64"
    
    # OpenBSD
    ["24"]="openbsd/amd64"
    ["25"]="openbsd/386"
    ["26"]="openbsd/arm"
    ["27"]="openbsd/arm64"
    
    # NetBSD
    ["28"]="netbsd/amd64"
    ["29"]="netbsd/386"
    ["30"]="netbsd/arm"
    ["31"]="netbsd/arm64"
    
    # Other
    ["32"]="android/arm64"
    ["33"]="solaris/amd64"
)

# Display options in columns
echo -e "${CYAN}Linux:${NC}"
echo "  1) linux/amd64        2) linux/386          3) linux/arm/5"
echo "  4) linux/arm/6        5) linux/arm/7        6) linux/arm64"
echo "  7) linux/mips         8) linux/mipsle       9) linux/mips64"
echo " 10) linux/mips64le    11) linux/ppc64      12) linux/ppc64le"
echo " 13) linux/riscv64     14) linux/s390x"
echo ""
echo -e "${CYAN}macOS:${NC}"
echo " 15) darwin/amd64      16) darwin/arm64"
echo ""
echo -e "${CYAN}Windows:${NC}"
echo " 17) windows/amd64     18) windows/386       19) windows/arm64"
echo ""
echo -e "${CYAN}FreeBSD:${NC}"
echo " 20) freebsd/amd64     21) freebsd/386       22) freebsd/arm"
echo " 23) freebsd/arm64"
echo ""
echo -e "${CYAN}OpenBSD:${NC}"
echo " 24) openbsd/amd64     25) openbsd/386       26) openbsd/arm"
echo " 27) openbsd/arm64"
echo ""
echo -e "${CYAN}NetBSD:${NC}"
echo " 28) netbsd/amd64      29) netbsd/386        30) netbsd/arm"
echo " 31) netbsd/arm64"
echo ""
echo -e "${CYAN}Other:${NC}"
echo " 32) android/arm64     33) solaris/amd64"
echo ""
echo -e "${YELLOW}Quick selections:${NC}"
echo " [a] All architectures"
echo " [l] All Linux"
echo " [c] Common (linux/amd64, linux/arm64, darwin/amd64, darwin/arm64, windows/amd64)"
echo ""

read -p "Enter selections (space-separated numbers, letters, or ranges like 1-6): " SELECTION

# Parse selection
SELECTED_ARCHS=()

if [[ $SELECTION =~ [aA] ]]; then
    # All architectures
    for key in $(echo ${!ARCHS[@]} | tr ' ' '\n' | sort -n); do
        SELECTED_ARCHS+=("${ARCHS[$key]}")
    done
elif [[ $SELECTION =~ [lL] ]]; then
    # All Linux
    for key in {1..14}; do
        SELECTED_ARCHS+=("${ARCHS[$key]}")
    done
elif [[ $SELECTION =~ [cC] ]]; then
    # Common platforms
    SELECTED_ARCHS=("linux/amd64" "linux/arm64" "darwin/amd64" "darwin/arm64" "windows/amd64")
else
    # Parse individual selections and ranges
    for item in $SELECTION; do
        if [[ $item =~ ^([0-9]+)-([0-9]+)$ ]]; then
            # Range (e.g., 1-6)
            start=${BASH_REMATCH[1]}
            end=${BASH_REMATCH[2]}
            for ((i=start; i<=end; i++)); do
                if [ -n "${ARCHS[$i]}" ]; then
                    SELECTED_ARCHS+=("${ARCHS[$i]}")
                fi
            done
        elif [[ $item =~ ^[0-9]+$ ]]; then
            # Single number
            if [ -n "${ARCHS[$item]}" ]; then
                SELECTED_ARCHS+=("${ARCHS[$item]}")
            fi
        fi
    done
fi

if [ ${#SELECTED_ARCHS[@]} -eq 0 ]; then
    echo -e "${RED}No valid architectures selected!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Building for ${#SELECTED_ARCHS[@]} architecture(s):${NC}"
for arch in "${SELECTED_ARCHS[@]}"; do
    echo "  - $arch"
done
echo ""

read -p "Continue? [Y/n]: " BUILD_CONFIRM
BUILD_CONFIRM=${BUILD_CONFIRM:-Y}
if [[ ! $BUILD_CONFIRM =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# ============================================
# CREATE MODIFIED SOURCE CODE
# ============================================

echo ""
echo -e "${BLUE}Generating source code with your configuration...${NC}"

# Hash password - FIX: Keep the leading $
PASSWORD_HASH=$(htpasswd -bnBC 12 "" "$PASSWORD" | tr -d ':\n' | sed 's/^[^$]*//')

if [ -z "$PASSWORD_HASH" ]; then
    echo -e "${RED}Failed to hash password!${NC}"
    exit 1
fi

# Verify hash starts with $
if [[ ! $PASSWORD_HASH == \$* ]]; then
    echo -e "${RED}✗ Hash is malformed (doesn't start with $)${NC}"
    exit 1
fi

# Write config.go
printf 'package main\n\nconst (\n\tUSERNAME      = "%s"\n\tPASSWORD_HASH = "%s"\n\tPORT          = ":%s"\n)\n' \
    "$USERNAME" "$PASSWORD_HASH" "$PORT" > config.go



BUILDING_UNIX=false
BUILDING_WINDOWS=false

for arch in "${SELECTED_ARCHS[@]}"; do
    if [[ $arch == windows/* ]]; then
        BUILDING_WINDOWS=true
    else
        BUILDING_UNIX=true
    fi
done

# Generate only what's needed
if [ "$BUILDING_UNIX" = true ]; then
    if [ -f "main_unix.go.template" ]; then
        cp main_unix.go.template main.go
        echo -e "${GREEN}✓ Generated main.go (Unix)${NC}"
    else
        echo -e "${RED}✗ main_unix.go.template not found!${NC}"
        exit 1
    fi
fi

if [ "$BUILDING_WINDOWS" = true ]; then
    if [ -f "main_windows.go.template" ]; then
        cp main_windows.go.template main_windows.go
        echo -e "${GREEN}✓ Generated main_windows.go (Windows)${NC}"
    else
        echo -e "${RED}✗ main_windows.go.template not found!${NC}"
        exit 1
    fi
fi


echo -e "${GREEN}✓ Source code generated with hashed credentials${NC}"

# ============================================
# ENSURE DEPENDENCIES
# ============================================

echo ""
echo -e "${BLUE}Checking dependencies...${NC}"

if [ ! -d "vendor" ]; then
    echo "Running go mod download..."
    go mod download
    echo "Running go mod vendor..."
    go mod vendor
    echo -e "${GREEN}✓ Dependencies vendored${NC}"
else
    echo -e "${GREEN}✓ Vendor directory exists${NC}"
fi

# ============================================
# BUILD
# ============================================

echo ""
echo -e "${BLUE}Starting build process...${NC}"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"

LDFLAGS="-s -w"
SUCCESS_COUNT=0
FAIL_COUNT=0

for arch in "${SELECTED_ARCHS[@]}"; do
    # Parse OS/ARCH/ARM
    IFS='/' read -r GOOS GOARCH GOARM <<< "$arch"
    
    # Set output filename
    OUTPUT="${BUILD_DIR}/${APP_NAME}-${GOOS}-${GOARCH}"
    
    if [ -n "$GOARM" ]; then
        OUTPUT="${OUTPUT}v${GOARM}"
    fi
    
    if [ "$GOOS" = "windows" ]; then
        OUTPUT="${OUTPUT}.exe"
    fi
    
    echo -ne "${YELLOW}Building ${GOOS}/${GOARCH}${GOARM:+v$GOARM}...${NC} "
    
    # Build
    if [ -n "$GOARM" ]; then
        CGO_ENABLED=0 GOOS="$GOOS" GOARCH="$GOARCH" GOARM="$GOARM" \
            go build -ldflags="$LDFLAGS" -o "$OUTPUT" >/dev/null 2>&1
        BUILD_STATUS=$?
    else
        CGO_ENABLED=0 GOOS="$GOOS" GOARCH="$GOARCH" \
            go build -ldflags="$LDFLAGS" -o "$OUTPUT" >/dev/null 2>&1
        BUILD_STATUS=$?
    fi
    
    if [ $BUILD_STATUS -eq 0 ] && [ -f "$OUTPUT" ]; then
        SIZE=$(du -h "$OUTPUT" | cut -f1)
        echo -e "${GREEN}✓${NC} (${SIZE})"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAIL_COUNT++))
    fi
done

# ============================================
# SUMMARY
# ============================================

echo ""
echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}   Build Summary${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""
echo -e "${GREEN}Successful builds: $SUCCESS_COUNT${NC}"
if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "${RED}Failed builds: $FAIL_COUNT${NC}"
fi
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Username: $USERNAME"
echo "  Password: HASHED (bcrypt)"
echo "  Port: $PORT"
echo "  Server Version: $SERVER_VERSION"
echo ""
echo -e "${GREEN}✓ Plaintext password NOT stored in binary${NC}"
echo -e "${GREEN}✓ Bcrypt hash stored instead (cost factor: 12)${NC}"
echo -e "${GREEN}✓ Commands are executed on the target system${NC}"
echo ""
echo -e "${YELLOW}Output directory:${NC} $BUILD_DIR/"
echo ""
if [ $SUCCESS_COUNT -gt 0 ]; then
    echo -e "${GREEN}Binaries:${NC}"
    ls -lh "$BUILD_DIR/" 2>/dev/null | tail -n +2 | awk '{printf "  %-50s %s\n", $9, $5}'
fi
echo ""
echo -e "${CYAN}================================================${NC}"
echo -e "${GREEN}Build complete!${NC}"
echo -e "${CYAN}================================================${NC}"
