# dig - DNS lookup utility

## Introduction

The `dig` utilty allows you to learn about domain names (AKA host names). It sends your query to you name servers and displays the information that it found. Typically, you'll be concerned with the ANSWER section in the response. It might look like the following. Learn more about `dig` using the links provided.

```
example.com.            172719  IN      A       208.77.188.166
```

## Links

* https://en.wikipedia.org/wiki/Dig_(command) - Description.
* https://toolbox.googleapps.com/apps/dig - run `dig` online.
* https://community.cloudflare.com/t/dns-sleuthing-with-dig/11851 - usage examples.

## Domain Propagated Results

When a DNS entry has been propagated, you'll see something like the following in the ANSWER section of your `dig` request.

```
;; ANSWER SECTION:
aa0aaf97851014d8b99ccb1545ccb262-1337176677.us-east-1.elb.amazonaws.com. 60 IN A 18.233.186.245
aa0aaf97851014d8b99ccb1545ccb262-1337176677.us-east-1.elb.amazonaws.com. 60 IN A 107.23.233.94
```

## COX Extended Error Results

Several ISPs are hijacking DNS searches. When a domain is not found, they will display their own search results based on the missing domain name. They perform this action by changing `dig` results, I think.

```
$ dig random-unknown.host
;; ANSWER SECTION:
random-unknown.host.	0	IN	A	92.242.140.2
$ ping finder.cox.net
PING finder.cox.net (92.242.142.2) 56(84) bytes of data.
```

Notice that the IP address of `finder.cox.net` is on the same subnet (92.242.0.0/21 perhaps).

The result is that if you see 92.242.X.Y in the `dig` results, the domain name is not being found.

## DNS Checker

If you want an independent source of truth about your domain names, consider using [DNS Checker](https://dnschecker.org/). It has the following tools:


* Domain DNS Validation
* Reverse DNS Lookup - IP to hostname
* DNS Lookup
* NS Lookup
* MX Lookup
* Flush DNS
* DMARC Validation
* DNS Health Report
* MX Record Validation
