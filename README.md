# indexer-services

Maintain the docker compose file for starting indexer services.

## *Indexer gotchas and FAQs*

---

### **Gas fee estimation errors**

Indexers may see a message like this in their logs from time to time:

`<transaction> WARN collect and distribute rewards: FAILED : Error: cannot estimate gas; transaction may fail or may require manual gas limit`

This could mean that your controller account is low on the operations token (DEV). Check your controller account balance on the Account tab of your indexer. If you have < 0.1 you probably need to hit the [faucet channel](https://discord.com/channels/796198414798028831/949038537053966446) on Discord for more DEV tokens.

### **Docker Compose version**

For anyone who encounters the `depends_on contains an invalid type, it should be an array` error when running `docker compose` it could well be that you're not on the latest version of Docker Compose. I managed to fall foul of this by running `apt install docker-compose` which installs v.1.25.0. This version does not parse version 3 `docker-compose.yml` files properly and cannot understand the (super useful) `depends_on` with `condition` features recently introduced to cut down on errors at startup.

The shortest way to fix this appears to be to uninstall Docker Compose and re-install it from the official guide rather than from apt. The below worked for me:

 - `sudo apt remove --purge docker-compose`
 - `sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose`
 - `sudo chmod +x /usr/local/bin/docker-compose`

If all has worked you should get `docker-compose version 1.29.2, build 5becea4c` from `docker-compose --version` and you can go ahead and pull/up.

This is the official installation guide which I encourage you to at least skim before trusting some random on the internet  https://docs.docker.com/compose/install/#install-compose-on-linux-systems

### Change default Postres password

Coming soon!

### UFW setup guide

Coming soon!

### Monitoring setup guide (Prometheus and Grafana)

Coming soon!

If anyone has any questions, corrections or amendments, please do hit me up on Discord - Big Jim | counterpoint