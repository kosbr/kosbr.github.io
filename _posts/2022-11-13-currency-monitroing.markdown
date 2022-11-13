---
layout: post
title:  "Currencies prices monitoring"
date:   2022-11-13 00:00:00 +0700
categories:
tags: Kubernetes Monitoring
---

![Logo](/images/articles/currency-monitoring/logo.png)

Today a lot of IT specialists work in some country and live in another country or even travel.
So we earn in one currency, but spend money in another currency. When changing price is volatile, one
may become quite nervous about that, because even small difference can lead to big looses or benefits.

I found myself in such not healthy state in 2022. I had almost all my expenses in Russian rouble, but
income in Euro. Both currencies were volatile especially Rouble. Many times a day I checked prices
and decided if it is time to sell or not. I wasn't ok about that, so I decided to create monitoring 
that would notify me about some important changes, and let me do my job instead of monitoring
exchange site.

### Data source

[Here](https://www.moex.com/ru/issue/EUR_RUB__TOM/CETS) is Moscow's exchange Euro price. I'm not
sure about its role today (when you read this article), but before it was the source of true 
about Euro-Rouble price. Everybody else just add some spread to this price. So I can monitor this price
to be notified about last changes.

![Moex](/images/articles/currency-monitoring/moex.png)

### Gathering data from Moscow Exchange

It hasn't any documented API, but it was easy to guess it via browser dev tools. So I created a simple
quarkus [application](https://github.com/kosbr/moex-exporter) that reads data from Moscow exchange
and publishes it as prometheus metrics. You can set up any currency which is available on the exchange in
config file, and it will be published as a metric.

### Observing results

Here is the typical graph of Euro price in Roubles for several days.

![Alert euro price](/images/articles/currency-monitoring/euro-alert.png)

You may see that exchange works only several hours per day, the rest of time the price in constant.

### When to alert

When to alert? This is actually a tricky question. In my case the most days it was quite stable (summer and later),
day fluctuations were not more than 1.5%. Grafana has a rich tool for alerts, so I tested a lot. 
On practice, I found such alert useful for me: **if a price changes more than 1 Rouble in the last 8 hours**. 
It means that change is not so big yet, but not usual - deserve my attention. 


