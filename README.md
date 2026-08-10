# Breakout FPGA

This project explores how to build a simple **Breakout-style video game directly in digital hardware**.

The final goal is to implement the game on an **FPGA**, without using a CPU to execute the game logic.

Rather than starting directly from HDL, we are approaching the project step by step: first understanding the game behavior, then designing its logic as digital circuits, and finally translating that architecture to an FPGA.

## Project structure

The project currently follows two parallel paths.

### Python game

A very simple Breakout-style game written in Python is included as a behavioral reference.

It allows us to play the game and identify the basic functions that will later have to be implemented in hardware, such as:

- paddle movement;
- ball movement;
- collisions;
- bricks;
- score and game state.

The Python version is therefore not the final implementation. It is a convenient way to understand and test how the game should behave before designing the corresponding digital logic.

### Digital circuit analysis

The same game is progressively decomposed into elementary digital functions.

For example, paddle control can be studied in terms of:

- input signals;
- clock;
- up/down counters;
- position registers;
- comparators;
- logic gates.

We are currently using **Digital**, an open-source digital logic simulator available on GitHub, to design and simulate these circuits before moving to the FPGA.

## From game to hardware

The general workflow of the project is:

**Python game → Game functions → Digital logic circuits → FPGA**

Each part of the game will first be understood at the behavioral level and then redesigned as a hardware circuit.

The aim is also educational and experimental: to make visible what normally happens behind the abstraction of software and to understand how a video game can emerge directly from counters, registers, gates, clocks and signals.

## Final goal

The final objective is to reproduce the complete Breakout-style game on an FPGA, including:

- player input;
- paddle position and movement;
- ball position and movement;
- collision detection;
- brick management;
- game state;
- video generation.

The project is developed incrementally, keeping the intermediate circuit designs and experiments as part of the repository.
