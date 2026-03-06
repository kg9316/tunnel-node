# SSH hardening

## Important safety rule
Do **not** disable password authentication for the admin account until SSH key login has been verified in a separate session.

## Recommended process
1. Confirm your admin key works:
   `ssh -i /path/to/key admin@server`
2. Keep that session open.
3. Add a per-user override, for example:

```text
Match User kg9316
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    PubkeyAuthentication yes
```

4. Test config:
   `sudo sshd -t`
5. Restart SSH:
   `sudo systemctl restart ssh`
6. Test login again from a new terminal.

## Optional extra hardening
After confirming key-only access works, you may also disable password login globally for SSH admins if that matches your operations model.
