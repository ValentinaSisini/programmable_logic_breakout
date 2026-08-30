# Practical Vivado Project Guide: From VHDL to FPGA Programming

This guide explains the complete **AMD Vivado** workflow for creating an RTL project, adding **VHDL** and **XDC constraints** files, checking the design with **RTL analysis**, running **synthesis** and **implementation**, generating the **bitstream**, and finally programming the FPGA.

All screenshots in this guide come from a project targeting the **Digilent Basys 3** board, based on the **AMD/Xilinx Artix-7 XC7A35T-1CPG236C** FPGA (`xc7a35tcpg236-1`).

> **Overall workflow**
>
> `VHDL + XDC` → `RTL / Elaboration` → `Synthesis` → `Implementation` → `Bitstream` → `FPGA Programming`

---

## Table of Contents

1. [Create a New Project](#1-create-a-new-project)
2. [Select the Board or FPGA Device](#2-select-the-board-or-fpga-device)
3. [Add the VHDL Files](#3-add-the-vhdl-files)
4. [Add the XDC Constraints File](#4-add-the-xdc-constraints-file)
5. [Check the Top Level](#5-check-the-top-level)
6. [RTL Analysis and Elaborated Design](#6-rtl-analysis-and-elaborated-design)
7. [Synthesis](#7-synthesis)
8. [Implementation](#8-implementation)
9. [Bitstream Generation](#9-bitstream-generation)
10. [Programming the FPGA](#10-programming-the-fpga)
11. [What Each Stage Represents](#11-what-each-stage-represents)
12. [Useful Checks Before Programming](#12-useful-checks-before-programming)

---

## 1. Create a New Project

Open Vivado and choose **Create Project** / **New Project**.

<img src="images/01-new-project.png" width="520" alt="New Project wizard">

Enter a project name and choose the folder where the project will be stored. It is usually convenient to keep **Create project subdirectory** enabled, so Vivado creates a dedicated subfolder for the project.

<img src="images/02-project-name.png" width="520" alt="Project name and location">

Click **Next**.

<img src="images/03-project-name-next.png" width="520" alt="Project name next">

For the project type, select **RTL Project**.

If you prefer to add your sources later, you can enable:

- **Do not specify sources at this time**

This creates the project container first and lets you add VHDL and constraints afterward.

<img src="images/04-project-type-rtl.png" width="520" alt="RTL Project selection">

---

## 2. Select the Board or FPGA Device

In the **Default Part** window, you can select the board directly if Vivado has the proper board files installed.

For the Basys 3:

- board: **Basys3**
- FPGA: **XC7A35T**
- package: **CPG236**
- speed grade: **-1**
- full part name: `xc7a35tcpg236-1`

<img src="images/05-select-basys3.png" width="760" alt="Select Basys3 board">

If the Basys 3 does not appear under the **Boards** tab, you can select the equivalent FPGA directly under the **Parts** tab.

At the end, Vivado shows a project summary. Check that **Board** and **Part** are correct, then click **Finish**.

<img src="images/06-project-summary.png" width="560" alt="Project summary">

---

## 3. Add the VHDL Files

From the **Sources** panel, click the **+** button, or use **Add Sources** from the Flow Navigator.

<img src="images/07-add-sources.png" width="700" alt="Add sources button">

Choose:

**Add or create design sources**

<img src="images/08-add-design-sources.png" width="520" alt="Add design sources">

In the next window, click **Add Files**.

<img src="images/09-add-files.png" width="520" alt="Add files dialog">

Select all `.vhd` files needed by the project.

In this example, the files are:

- `breakout_vga_top.vhd`
- `button_onepulse.vhd`
- `counter_74193_style.vhd`
- `sevenseg_hex.vhd`

<img src="images/10-select-vhdl-files.png" width="760" alt="Select VHDL files">

After adding them, Vivado shows the list of design sources that will be included in the project.

<img src="images/11-vhdl-files-added.png" width="540" alt="VHDL files added">

### Copy sources or reference them?

The option **Copy sources into project** creates a copy of the files inside the Vivado project structure.

- **If enabled:** the Vivado project keeps its own copy of the source files.
- **If disabled:** Vivado uses the files from their original location.

For a Git repository where the VHDL files are already organized in a folder such as `src/`, it is often better **not to duplicate them**, so there is only one real source copy to maintain. The important thing is to be aware of which strategy you are using.

---

## 4. Add the XDC Constraints File

VHDL files describe the **logic** of the circuit. The `.xdc` file describes the **physical and timing constraints** of the project.

To add it, use **Add Sources** again, but this time select:

**Add or create constraints**

<img src="images/12-add-constraints.png" width="520" alt="Add constraints">

Then click **Add Files** and choose the `.xdc` file.

For a Basys 3 project, the XDC file is typically used to specify, for example:

- which VHDL port goes to which **physical FPGA pin**;
- the electrical standard, for example `LVCMOS33`;
- the clock pin;
- timing constraints for the clock;
- the pins associated with VGA, buttons, switches, LEDs, seven-segment displays, and so on.

Conceptual example:

```tcl
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 [get_ports clk]
```

The name inside `get_ports`, for example `clk`, must match **exactly** the port name declared in the top-level VHDL entity.

> **Important:** VHDL defines *what the circuit does*; the XDC file defines *how that circuit is connected to the FPGA and the real board*.

---

## 5. Check the Top Level

Vivado must know which VHDL entity represents the complete circuit to be synthesized.

In the example project, the top level is:

```text
breakout_vga_top
```

Vivado often detects it automatically. If not:

1. open **Sources → Design Sources**;
2. right-click the main file/entity;
3. choose **Set as Top**.

All other VHDL modules then become submodules instantiated under that top-level design.

---

## 6. RTL Analysis and Elaborated Design

Before synthesis, it is useful to inspect the RTL description.

In the Flow Navigator, use the **RTL ANALYSIS** section.

<img src="images/13-rtl-analysis-menu.png" width="280" alt="RTL Analysis menu">

### Run Linter

The **linter** highlights possible HDL issues, for example:

- suspicious constructs;
- unused signals;
- width mismatches;
- problematic assignments;
- situations that could generate hardware different from what you intended.

A warning is not always an error, but it should always be read and understood.

### Open Elaborated Design

The **Elaborated Design** shows how Vivado interprets the hierarchy and connections described by your VHDL **before true technology mapping and implementation**.

<img src="images/14-elaborated-design.png" width="900" alt="Elaborated Design schematic">

Here you can inspect:

- instantiated entities and components;
- input/output ports;
- buses;
- multiplexers;
- recognized registers and counters;
- connections between blocks;
- the hierarchical structure.

This stage answers the question:

> **“Did Vivado understand my VHDL the way I intended?”**

The Elaborated Design is **not yet** the final physical circuit inside the FPGA.

---

## 7. Synthesis

Once the RTL structure looks correct, run:

**SYNTHESIS → Run Synthesis**

<img src="images/15-run-synthesis.png" width="280" alt="Run Synthesis">

Synthesis transforms the VHDL description into a **technology-specific netlist** compatible with the selected FPGA.

At this stage Vivado decides how to implement the logic using resources such as:

- LUTs;
- flip-flops;
- carry chains;
- dedicated multiplexers;
- block RAMs, if needed;
- DSP blocks, if needed;
- I/O buffers;
- other Artix-7 primitives.

After synthesis, open **Open Synthesized Design**.

<img src="images/16-synthesized-design.png" width="900" alt="Synthesized Design">

At this point the project has already been translated into resources that can exist on the FPGA, but **their exact final placement and physical routing have not yet been completed**.

Useful things to check here include:

- the **Utilization Report**;
- any synthesis warnings;
- the number of LUTs and flip-flops used;
- recognized clocks;
- I/O ports;
- the synthesized netlist schematic.

---

## 8. Implementation

After synthesis, run:

**IMPLEMENTATION → Run Implementation**

<img src="images/17-run-implementation.png" width="280" alt="Run Implementation">

Implementation includes, in simplified terms:

1. netlist optimization;
2. **placement**: choosing the physical FPGA resources;
3. **routing**: choosing the physical interconnections between those resources;
4. checking timing and physical constraints.

After the process completes, open **Open Implemented Design**.

<img src="images/18-implemented-design.png" width="900" alt="Implemented Design">

This view is very different from the Elaborated Design: here you are looking at the project **actually placed and routed inside the FPGA device**.

The highlighted routing lines and physical regions show where Vivado has really placed the logic.

### Timing

After implementation, it is important to check the **Timing Summary / Timing Analysis**.

In particular, make sure there are no timing violations. In a synchronous project, the key question is:

> **“Can the circuit complete all required operations between one clock edge and the next?”**

If the project shows `WNS >= 0` and no other relevant violations, the main timing constraints are satisfied.

---

## 9. Bitstream Generation

Once implementation has completed successfully, use:

**PROGRAM AND DEBUG → Generate Bitstream**

<img src="images/19-generate-bitstream.png" width="280" alt="Generate Bitstream">

The **bitstream** is the binary file that contains the information required to configure the programmable resources of the FPGA according to the implemented design.

For a project whose top level is `breakout_vga_top`, the file will usually have a name such as:

```text
breakout_vga_top.bit
```

Vivado usually stores it inside the project directory, in the implementation run folder, for example:

```text
<project>.runs/impl_1/breakout_vga_top.bit
```

You do not need to manually copy this file in order to program the board: the Hardware Manager can use the bitstream directly from the project.

---

## 10. Programming the FPGA

After generating the bitstream:

1. connect the **Basys 3** board to the computer via USB;
2. power on the board;
3. in Vivado, open **PROGRAM AND DEBUG → Open Hardware Manager**;
4. choose **Open Target → Auto Connect**;
5. Vivado should detect the Artix-7 device on the board;
6. select the device, usually something like `xc7a35t_0`;
7. choose **Program Device**;
8. verify that the correct `.bit` file is selected;
9. click **Program**.

After a few seconds, the FPGA is configured and your circuit begins to run.

### Important: this configuration is volatile

Programming with a `.bit` file configures the FPGA SRAM directly. If you power off the Basys 3, the configuration is lost.

For normal development work, this is exactly what you want. If you want the design to load automatically at power-up, you must program the **non-volatile configuration memory** on the board instead; that is a separate procedure.

---

## 11. What Each Stage Represents

| Stage | Main question | Result |
|---|---|---|
| **VHDL** | What logical behavior do I want? | RTL description |
| **XDC** | To which pins and under which constraints must it be connected? | Physical/timing constraints |
| **RTL Elaboration** | Did Vivado interpret the hierarchy and connections correctly? | Elaborated logical circuit |
| **Synthesis** | With which FPGA resources can this be implemented? | Technology netlist |
| **Implementation** | Where are those resources placed and how are they connected physically? | Placed & routed design |
| **Bitstream** | How do I actually configure the programmable fabric? | `.bit` file |
| **Program Device** | How do I transfer that configuration to the board? | Configured FPGA |

In a more compact form:

```text
VHDL
  ↓
RTL Elaboration
  ↓
Synthesis
  ↓
LUT / FF / carry / I/O / other FPGA resources
  ↓
Placement + Routing
  ↓
Bitstream
  ↓
Real FPGA
```

---

## 12. Useful Checks Before Programming

Before generating the bitstream, it is a good idea to verify at least the following points:

- the **Top Level** is the correct one;
- there are no VHDL errors;
- the synthesis warnings have been read and understood;
- all required external ports appear in the XDC file;
- the names used in `get_ports` match the top-level VHDL ports exactly;
- the assigned pins are correct for the target board;
- the `IOSTANDARD` values are correct;
- the clock has an appropriate timing constraint;
- synthesis completed without errors;
- implementation completed without errors;
- timing constraints are met;
- there are no unconstrained I/O ports that Vivado reports as critical.

---

## Practical Note for the Basys 3 Project

In the Basys 3 case, the VHDL design remains largely independent from the physical FPGA package. The **XDC** file is what connects the logical top-level port names to the real board pins.

For example, a VHDL output such as:

```vhdl
VGA_R : out std_logic_vector(3 downto 0)
```

does not, by itself, know which physical FPGA pins it uses. The XDC lines are what connect `VGA_R(0)`, `VGA_R(1)`, and so on to the package pins that, on the Basys 3, reach the resistor network and then the VGA connector.

This gives a clean separation between two levels:

- **VHDL:** logical design;
- **XDC:** connection between the logical design and the concrete hardware board.

---

## Suggested Repository Structure

To keep source files separate from the large number of files automatically generated by Vivado, a simple repository structure can be:

```text
circuit_breakout/
├── README.md
├── src/
│   ├── breakout_vga_top.vhd
│   ├── button_onepulse.vhd
│   ├── counter_74193_style.vhd
│   └── sevenseg_hex.vhd
├── constraints/
│   └── basys3.xdc
├── docs/
│   └── images/
└── vivado/
    └── vhdl_breakout/       # Vivado project and generated files
```

In a Git repository, you will usually want to preserve carefully the **VHDL source files**, the **XDC constraints**, and possibly a project-creation script, while many temporary and generated Vivado files can be excluded through `.gitignore`.

---

**Board used in the screenshots:** Digilent Basys 3 — AMD/Xilinx Artix-7 `xc7a35tcpg236-1`.
