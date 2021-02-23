# Fractal (by Artur Begyan)

Fractal is an ML-powered network of interconnected public chats that allows branching of chats into more focused “sub-chats”, thereby overcoming the problem of
rapid conversation subject dilution and low engagement. Fractal aims to allow unacquainted individuals to spontaneously find and discuss niche topics of common interest in real-time.

This repository contains the code that powers Fractal's IOS and Android front-end interfaces. It is written using the Flutter Framework by Google https://flutter.dev/.

## App Screenshots

![shot 1](750x750bb-1.jpg?raw=true)
![shot 2](750x750bb-2.jpg?raw=true)
![shot 1](750x750bb-3.jpg?raw=true)
![shot 2](750x750bb-4.jpg?raw=true)
![shot 2](750x750bb-5.jpg?raw=true)
![shot 2](750x750bb-6.jpg?raw=true)
![shot 2](750x750bb-7.jpg?raw=true)


The current version of Fractal imports hot submissions from the r/worldnews subreddit and converts them into native Fractal chats where users can engage in discussions in a more interactive environment by just messaging each other.

Each message in a Fractal chat can be turned into a subchat of the parent chat it was initially created in. This feature of branching chats into more focused subchats aims to encourage the users to discuss niche topics of common interest in real time in an engaged manner.

By double-tapping or long-pressing a message anyone can "zoom" into the message and navigate to the subchat that is centred around the specific message of the "parent" chat (https://appadvice.com/game/app/fractal/1459580178).


## Project Structure

This is a Flutter mobile application targeting Android and IOS. The code for the flutter app is in the folder named lib. Additionally, this repo contains a series of Firebase configuration files and cloud functions. Fractal also supports real-time search powered by Algolia (https://www.algolia.com/).


