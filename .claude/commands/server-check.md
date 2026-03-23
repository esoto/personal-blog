# Server Health Check

Run a comprehensive health check on the Hetzner VPS (178.104.88.183) hosting the blog.

## Checks to Run

Run all checks in parallel where possible via SSH to `root@178.104.88.183`:

### 1. App Health
```bash
curl -s -o /dev/null -w "%{http_code}" https://blog.estebansoto.dev/up
```
Expected: 200

### 2. Container Status
```bash
ssh root@178.104.88.183 'docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
```
Expected: All 4 containers running (web, kamal-proxy, db, backups)

### 3. Disk Usage
```bash
ssh root@178.104.88.183 'df -h / && echo "---Docker:" && docker system df'
```
Alert if disk > 80%

### 4. Memory & Swap
```bash
ssh root@178.104.88.183 'free -h'
```
Alert if available memory < 500MB or swap usage > 50%

### 5. Database
```bash
ssh root@178.104.88.183 'docker exec personal-blog-db pg_isready -U blog'
```
Expected: accepting connections

### 6. Backup Status
```bash
ssh root@178.104.88.183 'docker exec personal-blog-backups ls -lt /backups/daily/ 2>/dev/null | head -5'
```
Alert if no backup in last 48 hours

### 7. SSL Certificate
```bash
echo | openssl s_client -connect blog.estebansoto.dev:443 -servername blog.estebansoto.dev 2>/dev/null | openssl x509 -noout -dates
```
Alert if expiring within 14 days

### 8. Security Updates
```bash
ssh root@178.104.88.183 'apt list --upgradable 2>/dev/null | grep -i security | head -10'
```
Alert if pending security updates

### 9. Docker Logs (Errors)
```bash
ssh root@178.104.88.183 'docker logs --since 24h personal-blog-web-$(docker ps --filter name=personal-blog-web --format "{{.Names}}" | head -1 | sed "s/personal-blog-web-//") 2>&1 | grep -i "error\|fatal\|exception" | tail -10'
```
Report any errors in last 24h

### 10. Fail2ban Status
```bash
ssh root@178.104.88.183 'fail2ban-client status sshd 2>/dev/null'
```
Report banned IPs if any

## Output Format

Present results as a table:

| Check | Status | Details |
|-------|--------|---------|
| App Health | OK/FAIL | HTTP status code |
| Containers | OK/FAIL | Count running |
| Disk | OK/WARN | Usage % |
| Memory | OK/WARN | Available |
| Database | OK/FAIL | Connection status |
| Backups | OK/WARN | Last backup date |
| SSL | OK/WARN | Expiry date |
| Security | OK/WARN | Pending updates count |
| App Errors | OK/WARN | Error count (24h) |
| Fail2ban | INFO | Banned IPs |

If anything is FAIL or WARN, provide remediation steps.
