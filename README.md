# Problem - RESOLVED ✓

~~I'm having an issue where I cannot pull container images from a private image repository on Docker Hub when I am SSH'd into a EC2 instance within AWS.~~

**Resolution**: Successfully able to pull container images from a private Docker Hub repository from an EC2 instance using a Personal Access Token (PAT). The reproduction steps below have been verified to work correctly.

## Reproduction Plan

### Prerequisites
- AWS account with appropriate EC2 permissions
- Docker Hub account with a private repository
- Docker Hub personal access token (PAT)
- SSH key pair for EC2 access

### Steps to Reproduce

1. **Launch EC2 Instance**
   - Use AMI: `al2023-ami-2023.9.20251027.0-kernel-6.1-x86_64`
   - Instance type: `t3.micro` or larger
   - Configure security group to allow SSH (port 22) from your IP
   - Attach an IAM role if needed for other AWS operations
   - Launch with your SSH key pair

2. **SSH into the EC2 Instance**
   ```bash
   ssh -i /path/to/your-key.pem ec2-user@<instance-public-ip>
   ```

3. **Install Docker on Amazon Linux 2023**
   ```bash
   sudo yum update -y
   sudo yum install -y docker
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -a -G docker ec2-user
   ```

   Log out and log back in for group changes to take effect:
   ```bash
   exit
   ssh -i /path/to/your-key.pem ec2-user@<instance-public-ip>
   ```

4. **Verify Docker Installation**
   ```bash
   docker --version
   docker info
   ```

5. **Test Pulling Public Image (Should Work)**
   ```bash
   docker pull hello-world
   docker images
   ```

6. **Login to Docker Hub with Personal Access Token**
   ```bash
   docker login -u <your-docker-username>
   # When prompted for password, enter your personal access token
   ```

7. **Verify Login Credentials**
   ```bash
   cat ~/.docker/config.json
   ```

   **What to expect in config.json:**
   After logging in with a PAT, you should see Docker Hub credentials stored in one of these formats:
   - An `auth` field under `https://index.docker.io/v1/` containing a base64-encoded string of `username:PAT`
   - A `credsStore` field referencing a credential helper (like `osxkeychain`, `wincred`, or `secretservice`)

   Example:
   ```json
   {
     "auths": {
       "https://index.docker.io/v1/": {
         "auth": "dXNlcm5hbWU6cGFzc3dvcmQ="
       }
     }
   }
   ```

   **Important**: The config.json should contain an entry for Docker Hub (`https://index.docker.io/v1/`), not other registries. If you only see entries for other registries (like JFrog or private registries), your Docker Hub login did not succeed.

8. **Pull Private Image (Should Succeed)**
   ```bash
   docker pull <your-username>/<private-repo>:<tag>
   # Example: docker pull demonstrationorg/dhi-python:3.13-fips-dev
   ```

9. **Verify Successful Pull**
   ```bash
   docker images | grep <private-repo>
   ```

### Expected Results
- Public images: Should pull successfully
- Private images: Should pull successfully after authentication with PAT

### Troubleshooting (if needed)

If you encounter issues pulling private images, verify:

1. **Check Docker logs**
   ```bash
   sudo journalctl -u docker -n 50
   ```

2. **Check network connectivity**
   ```bash
   ping -c 4 registry-1.docker.io
   curl -v https://registry-1.docker.io/v2/
   ```

3. **Verify DNS resolution**
   ```bash
   nslookup registry-1.docker.io
   ```

4. **Check for proxy or firewall issues**
   ```bash
   echo $HTTP_PROXY
   echo $HTTPS_PROXY
   ```

5. **Verify you're authenticated to Docker Hub** - Check that `~/.docker/config.json` contains an entry for `https://index.docker.io/v1/`

### Diagnostic Information (for troubleshooting)
- Exact error message from `docker pull`
- Docker version: `docker --version`
- Network configuration: VPC, subnets, security groups, NACLs
- IAM role attached to EC2 instance (if any)
- Output from `docker login` command
- Content of `~/.docker/config.json` (redact sensitive tokens)

## Key Takeaways

1. **Authentication matters**: Ensure `docker login` is executed for Docker Hub specifically, not another registry
2. **Verify config.json**: After login, check that `~/.docker/config.json` contains an entry for `https://index.docker.io/v1/`
3. **PAT format**: The `auth` field contains a base64-encoded string of `username:PAT`, not an OAuth token
4. **Architecture considerations**: Verify the image supports your EC2 instance's architecture (e.g., arm64 vs x86_64)