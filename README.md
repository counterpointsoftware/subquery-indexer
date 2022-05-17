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

### **Change default Postres password**

Credit to Michael from the SubQuery team here as I've just lifted his exact response from Discord to try and pull all these essential items together in this document. I have tested running these exact steps and they work great. TODO

For `coordinator-service: v0.18.0` you can change postgres password, just make sure the password config for db is same with the one for coordinator service.
```
// For postgres db
POSTGRES_PASSWORD: your_password
// For coordinator
command:
  - --postgres-password: your_password
```
However, we don't support to apply the changed password to the existing data ATM, so there has several steps to apply the changes manually:
```
// 1. change existing db password manually
docker exec -i db_container_id psql -U postgres -c "ALTER USER postgres WITH PASSWORD 'your_password'"

// 2. restart docker compose
docker-compose up -d

// 3. For the running projects, there is a tricky way to force restart the
// project with new db password (force restart for be supported as a option flag in the future)
// you can force remove the running query containers, then press `restart project` 
// with the previous form values in admin app.
docker stop query_qmyr8xqgaxucxmp query_qmszpq9f4u1gerv
docker rm query_qmyr8xqgaxucxmp query_qmszpq9f4u1gerv
```

### **UFW setup guide**

NOTE: Everyone's setup is different and what worked for me might not be the best solution (or even work) for you. I suggest you consider all options before deciding on which route to take.

Uncomplicated Firewall (UFW) is a popular Linux firewall that ships with Ubuntu.

Docker modifies your server's IP tables directly to setup the networks you configure and ports you expose with the likes of this in a `docker-compose.yml`: 
```
ports:
      - 80:80
```
This means that it is able to bypass any UFW configuration you may have setup. The end result is that you may have set a UFW rule to block incoming connections on certain ports but this configuration is then rendered ineffective as the ports remain open to The Internet. Not great if we're talking about an admin interface or a database engine that would be a target for the multitude of hackers out there!

There are a number of approaches to manage this, here are a few:

1. Disable the IP tables option in Docker.
   * Pros
     * Immediately stops Docker overriding the UFW configuration.
   * Cons
     * Requires additional configuration to fix up the way Docker creates networks which allow the containers to talk to each other.
     * FULL DISCLOSURE: I found option 3 below before I went too far down this rabbit hole so it may not be too bad to configure.
2. Use `expose` instead of `ports` in the `docker-compose.yml`.
   * Pros
     * Nice and neat as the change is only in our docker compose file which is where we are defining the rest of the behaviour in our stack.
   * Cons
     * The `query_` containers that are created to index a project need to talk to other containers in the stack. They do this by running on a specific port which gets allocated when they are created starting at 3000 and incrementing with each project indexed.
     * That makes `expose` a little awkward - either suffer the disruption of adding/removing the internal port as projects are added/removed or just expose a bunch (3000 - 3100 for example) up front and hope you don't forget when your 101st project won't index.
     * Means that if you pull the latest from the official repository you may overwrite the change in `docker-compose.yml`.
3. Configure UFW with a bunch of additional rules that drop messages to the Docker container ports unless you explicitly allow them.
   * Pros
     * Allows Docker to maintain its IP table use - the default behaviour.
     * Allows UFW to function as it was always intended to.
   * Cons
     * Difficult to do (but I've made it easier with this guide).
4. Use your VPS/VDS provider's firewall.
   * Pros
     * Probably the easiest solution of all of them. Definitely less effort than the route I've gone so well worth considering.
   * Cons
     * Unavailable to me.

Credit for suggesting option 1 first has to go to crypto_new on Discord.

Credit for suggesting options 2, 3 and 4 first has to go to kw1k on Discord (thanks!).

For me, option 3 is the best fit as it allows me to use UFW as it was intended so ports that are not in use by Docker containers can still be controlled with regular UFW rules. It also means that I don't have to manage ports for the `query_` containers which would add to the maintenance overhead further down the line.

It does sound difficult to do though right? Well, it is. But we can stand on the shoulders of giants here as someone has put together a guide on how to do it along with a comprehensive explanation of how it all works. Please do have a read here [To Fix The Docker and UFW Security Flaw Without Disabling Iptables](https://hub.docker.com/r/chaifeng/ufw-docker-agent/).

What I've actually done is written a bash script to configure the firewall from scratch every time I run it. You can find it here: [ufw-setup.sh](https://github.com/counterpointsoftware/subquery-indexer/blob/documentation-gotchas-and-faqs/ufw-setup.sh) and you can download it using this command:
```
curl https://raw.githubusercontent.com/counterpointsoftware/subquery-indexer/documentation-gotchas-and-faqs/ufw-setup.sh -o ufw-setup.sh
```
To walk you through what's happening, it resets any existing configuration, applies some default rules to allow all outgoing connections and then deny all incoming. It then adds the special behaviour suggested by chaifeng above by writing the rules into the `/etc/ufw/after.rules` file which gets run when the firewall is activated. From there we can start adding our exceptions.

Note that the link above is not my actual one, rather a template of mine you can adapt to your own needs. Specifically, you probably want to lock down port 8000 to your own static IP by uncommenting and editing this line and entering your own IP (if you do this, remove or comment the line above that allows everyone access):
```
#ufw route allow proto tcp from <your IP address> to any port 8000
```
You will need to add rules for any other software in your stack such as monitoring which you will need to access from the outside world.

Finally, you can run it with this command:
```
sudo bash ufw-setup.sh
```

### **Monitoring setup guide (Prometheus and Grafana)**

Coming soon!

If anyone has any questions, corrections or amendments, please do hit me up on Discord - Big Jim | counterpoint