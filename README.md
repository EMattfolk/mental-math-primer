# TDDD27 Project: Mental Math Primer

## Functional specification

This project is a single page webapp that would work similar to something like
[Mental Math Master](https://play.google.com/store/apps/details?id=com.fivedaysweekend.math&gl=US)
on Google play.

There would be several categories of problems to train on and within each
category automatically generated problems that need to be solved to progress.
Problems would be multiple choice and have a timer attached to encourage speed.

Possible extensions

- Save progress with a Google account
- A leaderboard
- Tips and tricks

## Techincal specification

The project will be built using [elm](https://elm-lang.org) (a functional web
framework comparable to React) for the front-end and Flask for the back-end.
The idea is that backend generates and verifies problems as well as saving
progress.

Additionally I will set up CI and possibly my own domain for the site.

If there is time I will set up Google auth using auth0 to sync data.

## Motivation for the project

I was helping my sister with math practice for Högskoleprovet and I wanted to
recommend a good practice tool which she could use to improve her speed.
Unfortunately there are no good and easily accessible apps for training mental
math in App Store or the web, so I thought I would create my own.

Additionally I want to explore the power of functional programming for
web apps. I work with people who praises functional programming highly (me
included), so I thought it was a perfect opportunity to try it out.
