---
layout: post
title:  "Simplex method intermediate solutions"
date:   2016-11-07 14:30:39 +0600
categories:
tags: Algorithms Forks
---

There are not so many java implementations of [simplex method][simplex]{:target="_blank"} in the internet. In my 
opinion the best one is [Apache Commons-math][commons-math]{:target="_blank"}. The library is huge and has a lof of 
other implemented math algorithms including simplex method. However, I haven't found any library for getting intermediate
solutions in simplex method, so I had to fork Apache commons-math.

### The problem

You know, that simplex method is a method for solving problem:

#### Maximize or minimize: 

![goal](/images/articles/simplex/goal.gif)

#### Subject to conditions: 

![conditions](/images/articles/simplex/conditions.gif)

#### Where 

![b](/images/articles/simplex/b.gif)
![x](/images/articles/simplex/x.gif)

A is matrix m x n. Vector X is a vector of variables. Actually the simplex method demands some additional 
constraints, but it can be reached by easy transformations and not important in current article.

The conditions create a polyhedron that limits some part of n dimensional space. The solution must be in the 
vertex. So the algorithm way is find at least one vertex and step by step go to solution step.

![Polyhedron](/images/articles/simplex/simplex.png)

In some cases it isn't necessary to find the most optimal point. For example, one may need not the most optimal point,
but at least point that is better than another point. When it is achieved the optimization may be stopped. Sometimes it 
can save a lot of time. 

### Solution
 
I've forked the original library to add this modification. My [fork][commons-math-my]{:target="_blank"} is placed here.
How to use it?

{% highlight java %}
SimplexSolver simplexSolver = new SimplexSolver();

// ... prepare constraintSet and goalFunction

simplexSolver.setSimplexSolverInterceptor(new SimplexSolverInterceptor() {
            public boolean intercept(PointValuePair pointValuePair) {
                // pointValuePair is intermediate solution
                // return if the optimization must be stopped here
                return false;
            }
        });

PointValuePair pair = simplexSolver.optimize(goalFunction, constraintSet, GoalType.MINIMIZE);
{% endhighlight %}

Just set the implementor of SimplexSolverInterceptor interface to SimplexSolver. It contains the only one method.
It has access to intermediate solution and returns if the optimization must be stopped. 

I'm going to suggest including it into original library, but even it is accepted, it will be published not so soon. 
That's why I've published it in jcenter repository. To download it add following lines to your pom.xml (if you use maven):

{% highlight xml %}
    <repositories>
 		<repository>
 			<snapshots>
 				<enabled>false</enabled>
 			</snapshots>
 			<id>bintray-dev-kosbr-maven</id>
 			<name>bintray</name>
 			<url>https://dl.bintray.com/dev-kosbr/maven</url>
 		</repository>
 	</repositories>
    <dependencies>
     <dependency>
            <groupId>com.github.kosbr</groupId>
            <artifactId>commons-math3</artifactId>
            <version>3.6.1.2</version>
        </dependency>
    </dependencies>
{% endhighlight %}

[simplex]: https://en.wikipedia.org/wiki/Simplex_algorithm
[commons-math]: https://github.com/apache/commons-math
[commons-math-my]: https://github.com/kosbr/commons-math
[jekyll]: https://jekyllrb.com/