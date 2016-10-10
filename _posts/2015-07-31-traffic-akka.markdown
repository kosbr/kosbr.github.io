---
layout: post
title:  "Traffic emulation with akka"
date:   2015-07-31 14:30:39 +0600
categories:
tags: Akka Training
---

I often hear positive feedback about [Akka][akka]{:target="_blank"} in different conferences. I'd like to use it
in practise, but I haven't appropriate tasks for it. So I decided to try it in training application which emulates
road traffic.

Akka is an actor model implementation in scala, but it has also java API. In short, actor model determines actors, which
all can do something in parallel, create new actors, send and receive messages. It is able to be used in large
distributed applications, but I just used it to satisfy my curiosity.

I wanted to emulate a road traffic. It is a very interesting process. Have you ever been in a traffic jam which suddenly
disappears without any hindrance? We always call it a traffic jam for no reason at all. However, it is possible a 
consequence of some hindrance that recently created traffic jam and even after disappearing in continue to influence 
on a traffic. Actually, a single hindrance creates wave of low speed which moves towards traffic. Also it is 
interesting to investigate the situation when a lof of different drivers met at road. The may be slow or fast, polite
or impudent. 

If I had a lot of time, I'd make a science work about it, because this topic is very interesting for me. However, I
had a few days, so I just had a nice toy to play with it. I planned to build model with following actors:

![Actors](/images/articles/akka/schema.png)

Let's start with client. It has a button to add a car to the road. Every car has a lot of parameters, which
 describe its style of moving. Every n seconds the road's state changes and 
immediately is being sent to client. I use a web sockets for connection with client. By the way, it is easy to set up
web sockets using spring boot. We have just a simple straight road. It is divided into cells. One car - one cell. 
A car can move a few cells forward, it also can change lane and move forward.

Here is the list of actors I've created.

* ManagerActor — creates all other actors in the beginning. It creates all new cars.

* CarActor — a car. It investigate road's state and makes a decision about next step. This decision should 
be sent to the DecisionActor. The DecisionActor could accept a step or return an error. An error means that 
some other car already uses this area and an accident is possible. In such case two cars have to exchange messages and
 reach an agreement about what car will be allowed to to this step. Of course, after this one or two cars have to send 
 one more message to the DecisionActor.

* DecisionActor — It collects all wished steps from cars and finds conflicts. In case of conflict it
suggests to resolve it by cars. After all steps are collected, all of them are will be sent to the RoadActor.

RoadActor — a road. It receives all steps of cars and refreshes state of road. All new stats are sent to the ViewActor
and to all cars(through DecisionActor)

ViewActor — Eyes. Transforms a road in appropriate form for client.

So, the basic login of the application is in CarActor. Every car has 3 parameters:

1. Wished speed (1, 2 or 3)
2. Politeness
3. Effrontery

The wished speed is a speed of a car without any hindrances. The politeness is a probability if a car will allow 
to get other car in its lane if it asks. The effrontery (maybe not appropriate term) is a probability if a car will
ask other car to get in its lane if this lane is more profitable. For example, if you see a slow car on your lane, 
you probably will want to get in next lane, so you'll have to ask a car next to you to get slower to allow you move to next
lane. Another way is waiting until lane is free and then move to next lane.

Before every step every car takes a road and makes a stack of possible steps. The most profitable step is on the top
of the stack. The most unprofitable step (stay at place) is the last in the stack. The most profitable step should be
sent to the DecisionActor. The DecisionActors collects steps and if it takes some step that leads to an accident, 
 it sends an error to a car that must give a way. The message contains a link to another car, so they can have a dialog.

If a car gets message about step inability, it has following ways:

* Take a next step form the stack and try send a decision one more time
* Ask another car to give a way. If it agrees, resend the current step.


Also it is needed to consider a situations when more than two cars wants to be at the same area. It is possible because
one step could cover a lof of road cells.

I've implemented it. The project is on the github. It is a web application, but now I expect only one client use it. 
Nonetheless it is a toy.

This is how it looks in a browser:
![Interface](/images/articles/akka/interface.png)

It is the panel of cars generator. In creates cars with defined parameters in the beginning of the road. It can 
generate a traffic with different density. By clicking on the road it is possible to put there a hindrance.  It is 
very interesting to see how it works and emulate different situations. IMHO, very similar to our roads. 

![Action](/images/articles/akka/action.png)


[akka]: http://akka.io/