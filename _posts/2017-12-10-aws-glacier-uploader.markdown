---
layout: post
title:  "AWS glacier multipart uploader"
date:   2017-12-11 10:30:39 +0600
categories:
tags: AWS
---

Recently I was finding the cloud for keeping backup of my personal data and I was
attracted by [AWS Glacier][glacier]{:target="_blank"} prices for data storage. Even the
way of presenting price is very attractive: "$0.004 per GB / month" - sounds like almost
free. However, I wouldn't say it is unique price, but anyway it is a good service in some cases
 and it would be good to have possibility to use it. This article is about personal data
  storage and my simple application for uploading files to AWS Glacier.
![Providers](/images/articles/uploader/storage-providers.png)

The diagram above compares month prices for storage 2 terabytes of data. The hard disk
means just to buy usual hard disks every 5 years. It is seen, that Google has too big price
and the rest services are rather cheap.

The question of a choice of backup solution can grow in a big discussion. Actually, there is
no one right way of doing it. Personally, I use all of them, but let me share some ideas about
AWG Glacier.

### AWS Glacier Features

It has many features that are described in the documentation, here I extracted
some significant facts from there:

Positive:
* Very big files uploading is supported (up to 10,000 x 4 GB)
* Rather good AWS account security
* Probability to select geographically where to store your data

Negative:
* It doesn't have UI, access is possible only by command line (not convenient) or API
* AWS needs several hours to prepare the data for downloading if someone suddenly decided to get an archive
* Uploads and Downloads are not free, but cheap.

It doesn't look like good every-day cloud, but I think it is a good solution for storing
long term data. For example, something, that should be passed from one generation to
the next one. The copy of very important family data can be encrypted and uploaded
to the proper data center, regarding the current politic situation to minimize risk of its
destroying because of conflicts and wars.

### How to use it

The default way of using AWS Glacier is AWS command line application. However, it is very
difficult even upload a file bigger than 100 mb. I tried to found some open source application,
that does it for me, but had found almost nothing. I was searching something like this:
[Glacier multipart uploader][uploader]{:target="_blank"}. The application should be open
source, primitive and well described. It is very important to be sure in such application
before giving it access to your important data. As I said, I had found nothing and created
it by myself.

The application is a small java program, the last jar can be downloaded [here][release]{:target="_blank"}.
The brief documentation is in [readme][uploader]{:target="_blank"} file. In short, it can
 upload files part by part and proceed uploading after failures. It makes possible to work
 with very big files. Now it can only upload files to the storage,
but cannot download them. I would like to have such instrument for downloading files, but now it
is to be done.

Finally, the small video example of using AWS uploader. (I'm not pro video blogger yet, so sorry for
sound quality)

<iframe src="https://player.vimeo.com/video/246781733" style="display:block; margin:0 auto;" width="640" height="360" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>

[glacier]: https://aws.amazon.com/glacier/
[uploader]: https://github.com/kosbr/glacier-multipart-uploader
[release]: https://github.com/kosbr/glacier-multipart-uploader/releases/latest