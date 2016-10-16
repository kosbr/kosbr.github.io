---
layout: post
title:  "Angular 2 guard router directive"
date:   2016-10-16 14:30:39 +0600
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
    path: 'view/:id',
    component: InfoComponent,
    canActivate: [RoleGuardService],
    data: {
      roles: [
        Roles.USER,
        Roles.ADMIN
      ]
    }
  } ,
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
    <a routerLink="view/19" routerLinkActive="highlighted">List</a>
</li>
<li>
    <a routerLink="list/12" routerLinkActive="highlighted">Page 12</a>
</li>
{% endhighlight %}

There are two links. When a state is active, corresponding link is highlighted. The problem is
 how to hide it (li tag) if a target state is forbidden? Unfortunately, I don't know simple way to do it now. Of course,
 I'm not going to check manually access for every link.

### How it should be done?

I'd like to have a directive, that hides whole element if the transition is not allowed. So it could be like this:

{% highlight html %}
<li appAllowTransition [destUrl]="'view/19'">
    <a routerLink="view/19" routerLinkActive="highlighted">List</a>
</li>
<li appAllowTransition [destUrl]="'list/12'">
    <a routerLink="list/12" routerLinkActive="highlighted">Page 12</a>
</li>
{% endhighlight %}

If I wanted to hide only link without container, I would may not use doubled parameter with destUrl. However, I'd like to have a
 possibility to hide blocks even without links. That's why I have two parameters with the same value.


### Implementation


#### Creating additional interface

Interface CanActivate contains only one method. It is called before transition and if it returns false, the transition will
 not happen. So the goal is call this method from the directive and hide element if it returns false. However, it is not easy because
  to call it the directive must have ActivatedRouteSnapshot and RouterStateSnapshot objects, but it doesn't have it.

{% highlight typescript %}
interface CanActivate {
    canActivate(route: ActivatedRouteSnapshot, state: RouterStateSnapshot): Observable<boolean> | Promise<boolean> | boolean;
}
{% endhighlight %}

A possible solution is create additional interface:

{% highlight typescript %}
interface Guard {
  allowTransition(allowedRoles: Roles[]): boolean;
}
{% endhighlight %}

It must have one method which accepts an object from data property of Route in routers configuration. In my case it is the list of roles which
are allowed to visit the target state. The implementation of this interface must know about roles that current user has and should return a
boolean result.

Then lets create a contract inside the application: all CanActivate implementations must implement Guard interface. So, my implementation will be
like this:

{% highlight typescript %}

@Injectable()
export class RoleGuardService implements CanActivate, Guard {

  //userService knows everything about the current user
  //router gives a possibility to redirect to login page
  constructor(@Inject('appUserService')
              private userService: UserService, private router: Router) {
  }

  canActivate(route: ActivatedRouteSnapshot,
              state: RouterStateSnapshot): Observable<boolean>|boolean {
    //get data object with roles which I configured
    let data: Data = route.routeConfig.data;
    if (data == null) {
      // no data => allow
      return true;
    }
    //I use Guard's method to get allow decision
    let allow = this.allowTransition(data['roles']);
    if (!allow) {
      this.router.navigate(['login']);
    }
    return allow;
  }


  allowTransition(allowedRoles: Roles[]): boolean {
    //some business logic, not important
    if (allowedRoles == null) {
      return false;
    }
    for (let i = 0; i < allowedRoles.length; i++) {
      let role = allowedRoles[i];
      if (this.userService.hasCurrentUserRole(role)) {
        return true;
      }
    }
    return false;
  }
}
{% endhighlight %}

By this step I've done nothing except extracting some logic of standard canActivate method to another method. Next task is creating a directive.

#### Creating a directive

The idea of directive is following:

1) import all necessary routes configuration
2) Parse all CanActivates from configuration and find appropriate one (which path matches with parameter)
3) Get the instances of all necessary CanActivates(which are Guards) and call allowTransition method.
4) Handle returned value.

The most difficult part is step 2 and 3. This is the piece of code which is processing it:

{% highlight typescript %}
let allow = true;

    //iterate over all familiar routes
    for (let i = 0; i < allroutes.length; i++) {
      let path = allroutes[i].path;
      if (this.pathMatch(path, this.destUrl)) {
        // path is corresponding

        //the array of canActivates which are also Guards
        let canActivate = allroutes[i].canActivate;

        //the array of allowed roles from data object.
        let allowedRoles = allroutes[i].data != null ? allroutes[i].data['roles'] : null;


        if (canActivate != null) {
          //iterate over all canActivates
          for (let a = 0; a < canActivate.length; a++) {
            try {
              //get the instance from the injector
              let canActivateInstance = this.injector.get(canActivate[a]) as Guard;

              //call method to get know if the target state is allowed
              if (!canActivateInstance.allowTransition(allowedRoles)) {
                allow = false;
                break;
              }
            } catch (error) {
              console.error('Error');
            }
          }
        }
      }
    }
{% endhighlight %}

I hope my comments will make the code clear for you. I used pathMatch method for check path matching. This methods contains a couple
of lines due to the [Route Matcher][routerMatcher]{:target="_blank"} library.

{% highlight typescript %}
import * as RM from 'route-matcher';

private pathMatch(template: String, test: String): boolean {
    return RM.routeMatcher(template).parse(test) != null;
}
{% endhighlight %}

The whole code of the directive is published below:


{% highlight typescript %}

@Directive({
  selector: '[appAllowTransition]'
})
export class AllowTransitionDirective implements OnDestroy, LoginListener, OnInit {

  private el: HTMLElement;

  private visibleDisplay: string;

  @Input()
  destUrl: string;

  constructor(el: ElementRef, private injector: Injector,
              @Inject('appUserService')
              private userService: UserService) {
    this.el = el.nativeElement;
    this.visibleDisplay = this.el.style.display;
  }

  ngOnDestroy() {
    this.userService.removeLoginListener(this);
  }


  ngOnInit() {
    // register directive in userService. It knows everything about current user and can notify the directive about changes.
    this.userService.addLoginListener(this);

    // first launch
    this.onLogin();
  }

  // implements the only one method of LoginListener
  onLogin() {
    let allow = true;

    //iterate over all familiar routes
    for (let i = 0; i < allroutes.length; i++) {
      let path = allroutes[i].path;
      if (this.pathMatch(path, this.destUrl)) {
        // path is corresponding

        //the array of canActivates which are also Guards
        let canActivate = allroutes[i].canActivate;

        //the array of allowed roles from data object.
        let allowedRoles = allroutes[i].data != null ? allroutes[i].data['roles'] : null;


        if (canActivate != null) {
          //iterate over all canActivates
          for (let a = 0; a < canActivate.length; a++) {
            try {
              //get the instance from the injector
              let canActivateInstance = this.injector.get(canActivate[a]) as Guard;

              //call method to get know if the target state is allowed
              if (!canActivateInstance.allowTransition(allowedRoles)) {
                allow = false;
                break;
              }
            } catch (error) {
              console.error('Error');
            }
          }
        }
      }
    }
    this.el.style.display = allow ? this.visibleDisplay : 'none';
  }

  private pathMatch(template: String, test: String): boolean {
    return RM.routeMatcher(template).parse(test) != null;
  }
}

{% endhighlight %}

You can found one more addition -  LoginListener interface and

[stackOverFlow]: http://stackoverflow.com/questions/38976109/hide-a-routerlink-if-its-associated-route-cannot-be-activated/39056222#39056222
[routerMatcher]: https://github.com/cowboy/javascript-route-matcher