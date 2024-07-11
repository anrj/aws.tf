# Note:
 Can't get cloudfront to wait for certificate validation. Although the certificate is created and correctly attached to distribution in the dashboard, terraform still shows an error and route53 record isn't being created anymore. Cyclic dependency is created if changing certificate arn with certificate_validation arn is used, 2 different records could be used.

![Project graph](https://i.postimg.cc/d1nk2Xzr/Screenshot-2024-06-25-at-21-42-19.png)

![Live Demo](https://i.postimg.cc/Y0yds4B2/thorium-Qa-Sp5-UMep-U.gif)