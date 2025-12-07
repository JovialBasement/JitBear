# Privacy SSH Server - JitBear

A minimal, privacy-focused SSH server with hardcoded authentication and zero logging. Built with Go and [gliderlabs/ssh](https://github.com/gliderlabs/ssh).

## Features

- ✅ **Zero Logging** - Complete silence, no connection logs, no auth logs
- ✅ **Hardcoded Authentication** - No PAM, no /etc/passwd, no system dependencies
- ✅ **Constant-Time Comparison** - Prevents timing attacks on password verification
- ✅ **Ephemeral Host Keys** - Generated fresh on each start (or embed your own)
- ✅ **Port Forwarding** - Full local (-L) and reverse (-R) SSH tunnel support
- ✅ **Single Static Binary** - No external dependencies
- ✅ **Cross-Platform** - Supports 30+ architectures
- ✅ **Customizable** - Easy configuration via build script

## Quick Start

### Prerequisites

- Go 1.21 or higher
- Git
- htpasswd (for password hashing)

### Clone and Build

## Dependencies

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install golang-go apache2-utils git
```

### CentOS/RHEL
```bash
sudo yum install golang httpd-tools git
```

### Arch Linux
```bash
sudo pacman -S go apache git
```

### macOS
```bash
brew install go httpd git
```


# Clone the repository
```bash
git clone https://github.com/JovialBasement/JitBear.git
cd privacy-ssh
```

# Run interactive build script
```bash
chmod +x build.sh

./build.sh
```

The build script will prompt you for:
- Username
- Password
- Listen port
- Target architectures

Binaries will be created in the `dist/` directory.

### Usage
```bash
# Start the server
./privacy-ssh

# Connect (from another terminal)
ssh username@localhost -p 2222

# With port forwarding
ssh username@server -p 2222 -L 8080:localhost:80 -R 9090:localhost:22
```

## Supported Architectures

The build script supports:

- **Linux**: amd64, 386, arm (v5/v6/v7), arm64, mips, mipsle, mips64, mips64le, ppc64, ppc64le, riscv64, s390x
- **macOS**: amd64 (Intel), arm64 (Apple Silicon)
- **Windows**: amd64, 386, arm64
- **FreeBSD**: amd64, 386, arm, arm64
- **OpenBSD**: amd64, 386, arm, arm64
- **NetBSD**: amd64, 386, arm, arm64
- **Android**: arm64
- **Solaris**: amd64

Quick selections in build script:
- `c` - Common platforms (Linux amd64/arm64, macOS, Windows)
- `l` - All Linux
- `a` - All architectures


## Security Notes

⚠️ **Important Security Considerations:**

- This server uses **hardcoded credentials** for maximum privacy but anyone with the binary can extract the hash
- **No logging** means no audit trail - use only in controlled environments
- Ephemeral host keys change on each restart (will trigger SSH warnings on reconnect)
- Designed for **privacy-focused use cases**, not general-purpose SSH access

### Recommendations:

1. **Use strong passwords** (20+ characters, random)
2. **Embed a persistent host key** if you don't want host key warnings
3. **Use non-standard ports** to avoid automated scans
4. **Restrict firewall access** to trusted IPs
5. **Build from source** to verify no backdoors

## Embedding a Persistent Host Key ( optional to get rid of host error )
```bash
# Generate a host key
ssh-keygen -t rsa -b 4096 -f hostkey -N ""

# Copy the contents of 'hostkey' (private key)
cat hostkey

# Paste into the templates in the embeddedHostKey constant:
const embeddedHostKey = `
-----BEGIN OPENSSH PRIVATE KEY-----
... paste here ...
-----END OPENSSH PRIVATE KEY-----
`

# Rebuild
./build.sh
```

## Port Forwarding

**Local forwarding** (-L): Access remote services locally
```bash
ssh user@server -p 2222 -L 8080:localhost:80
# Access server's port 80 via your localhost:8080
```

**Reverse forwarding** (-R): Expose local services to remote
```bash
ssh user@server -p 2222 -R 9090:localhost:22
# Server can access your local port 22 via its port 9090
```


## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Disclaimer

This software is provided for educational and privacy research purposes. Users are responsible for compliance with applicable laws and regulations. The authors assume no liability for misuse.

## Credits

Built with:
- [gliderlabs/ssh](https://github.com/gliderlabs/ssh) - SSH server library
- [golang.org/x/crypto](https://golang.org/x/crypto) - Go cryptography

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/privacy-ssh/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/privacy-ssh/discussions)

## Star History

If you find this project useful, please consider giving it a ⭐️!
