---
layout: post
title:  "Angular 2 guard router directive"
date:   2016-10-13 14:30:39 +0600
categories:
tags: Angular2 
---

A few weeks ago while I was developing my Angular 2 application I faced with problem: How to hide routerLinks if the 
transition is not allowed? I could'nt find any simple solution so I had to create my own one. Also I've found the similar
question in [stackOverFlow][stackOverFlow]{:target="_blank"} and shared my idea. This post describes this problem and 
the solution in details. However, I don't like this solution and waiting for better one, I'll explain it at the end.

### Problem description

We configure routes in Angular2 by creating array of Route objects. 

{% highlight typescript %}
export const itemRoutes: Routes = [
  {
    path: 'list',
    component: ListComponent,
    canActivate: [RoleGuardService],
    data: {
      roles: [
        Roles.USER,
        Roles.ADMIN
      ]
    }
  },
  {
    path: 'list/:page',
    component: ListComponent,
    canActivate: [RoleGuardService],
    data: {
      roles: [
        Roles.USER,
        Roles.ADMIN
      ]
    }
  }
]
{% endhighlight %}

And then it is possible to use such routerLinks to change state:

{% highlight html %}
<li>
    <a routerLink="list" routerLinkActive="highlighted">List</a>
</li>
<li>
    <a routerLink="list/12" routerLinkActive="highlighted">Page 12</a>
</li>
{% endhighlight %}

There are two links. When a state is active, corresponding link is highlighted. The problem is
 how to hide it (li tag) if a target state is forbidden? Unfortunately, I don't know simple way to do it now. 

### How it should be done?

I'd like to have a directive, that hides whole element if the transition is not allowed. So it could be like this:

{% highlight html %}
<li appAllowTransition [destUrl]="'list'">
    <a routerLink="list" routerLinkActive="highlighted">List</a>
</li>
<li appAllowTransition [destUrl]="'list/12'">
    <a routerLink="list/12" routerLinkActive="highlighted">Page 12</a>
</li>
{% endhighlight %}

I'll tell how I've created this directive below.

### Implementation


[stackOverFlow]: http://stackoverflow.com/questions/38976109/hide-a-routerlink-if-its-associated-route-cannot-be-activated/39056222#39056222