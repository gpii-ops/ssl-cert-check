# SSL Certification Expiration Checker:

ssl-cert-check is a Bourne shell script that can be used to report on expiring SSL certificates. The script was designed to be run from cron and can e-mail warnings or log alerts through nagios.

# Usage:
<pre>
$ ./ssl-cert-check
Usage: ./ssl-cert-check [ -e email address ] [ -E sender email address ] [ -x days ] [-q] [-a] [-b] [-h] [-i] [-n] [-N] [-v]
       { [ -s common_name ] && [ -p port] } || { [ -f cert_file ] } || { [ -c cert file ] } || { [ -d cert dir ] }"

  -a                : Send a warning message through E-mail
  -b                : Will not print header
  -c cert file      : Print the expiration date for the PEM or PKCS12 formatted certificate in cert file
  -d cert directory : Print the expiration date for the PEM or PKCS12 formatted certificates in cert directory
  -e E-mail address : E-mail address to send expiration notices
  -E E-mail address : Sender E-mail address
  -f cert file      : File with a list of FQDNs and ports
  -h                : Print this screen
  -i                : Print the issuer of the certificate
  -k password       : PKCS12 file password
  -n                : Run as a Nagios plugin
  -N                : Run as a Nagios plugin and output one line summary (implies -n, requires -f or -d)
  -P                : Display certificate metrics in Prometheus format
  -p port           : Port to connect to (interactive mode)
  -s commmon name   : Server to connect to (interactive mode)
  -t type           : Specify the certificate type
  -q                : Don't print anything on the console
  -v                : Specify a specific protocol version to use (tls, ssl2, ssl3)
  -V                : Only print validation data
  -x days           : Certificate expiration interval (eg. if cert_date < days)
</pre>

# Examples:

Print the expiration times for one or more certificates listed in ssldomains:

<pre>
$ ssl-cert-check -f ssldomains
Host                                            Status       Expires      Days Left
----------------------------------------------- ------------ ------------ ----------
www.prefetch.com:443                            Valid        May 23 2006  218
mail.prefetch.net:993                           Valid        Jun 20 2006  246
gmail.google.com:443                            Valid        Jun 7 2006   233
www.sun.com:443                                 Valid        May 11 2009  1302
www.spotch.com:443                              Connection refused Unknown Unknown
</pre>

Check all certificates with file pattern "/etc/haproxy/ssl/\*.pem"

<pre>
$ ssl-cert-check -d "/etc/haproxy/ssl/*.pem"
Host                                            Status       Expires      Days
----------------------------------------------- ------------ ------------ ----
FILE:/etc/haproxy/ssl/example1.org.pem      Valid        Jan 6 2017   78
FILE:/etc/haproxy/ssl/example2.org.pem      Valid        Jan 1 2017   73
FILE:/etc/haproxy/ssl/example3.org.pem      Valid        Jan 6 2017   78
</pre>

Send an e-mail to admin@prefetch.net if a domain listed in ssldomains will expire in the next 60-days:

<pre>
$ ssl-cert-check -a -f ssldomains -q -x 60 -e admin@prefetch.net
</pre>

Check certificate for a domain and output metrics in Prometheus format:

<pre>
$ ssl-cert-check -s google.com -p 443 -x 29 -P
# HELP certificate_status Certificate status (i.e valid, expiring).
# TYPE certificate_status gauge
certificate_status{name="google.com:443",condition="Valid"} 1
# HELP certificate_days_left Days left before the expiration.
# TYPE certificate_days_left gauge
certificate_days_left{name="google.com:443"} 57
</pre>

# Additional Documentation

Documentation And Examples: http://prefetch.net/articles/checkcertificate.html

## Building

### Master

On push/merge to master, CI will automatically build and push
`gpii/ssl-cert-check:latest` image.

### Tags

Create and push git tag and CI will build and publish corresponding`
`gpii/ssl-cert-check:${git_tag}` docker image.

#### Tag format

Tags should follow actual service-account-assigner version, suffixed by
`-gpii.${gpii_build_number}`, where `gpii_build_number` is monotonically
increasing number denoting Docker image build number,  starting from `0`
for each upstream version.

Example:
```
0.0.3-gpii.0
0.0.3-gpii.1
...
0.0.4-gpii.0
```

### Manually

Run `make` to see all available steps.

- `make build` to build image as latest
- `make push` to push this image to registry
