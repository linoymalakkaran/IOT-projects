# Water Treatment (WAT) Project
## IoT-Based Monitoring and Control Solution

## Table of Contents
- [Business Context](#business-context)
- [Project Requirements](#project-requirements)
  - [Network Requirements](#network-requirements)
  - [Solution Requirements](#solution-requirements)
  - [Data Volume & Performance Requirements](#data-volume--performance-requirements)
  - [Solution Constraints](#solution-constraints)
- [Deliverables](#deliverables)
- [Evaluation Criteria](#evaluation-criteria)

## Business Context

WAT operates independently but reports to the regional water authority. The organization is responsible for:

- Managing wastewater treatment (collection) and water reuse for the catchment area
- Processing wastewater to make it suitable for re-use in homes, businesses, and irrigation
- Reporting to regulatory authorities when releasing untreated wastewater during flooding events
- Monitoring inflow levels, water quality, outflow volumes, and equipment health

The WAT uses an IoT-based water meter system to control valves, monitor usage, and report to the SCADA system.

## Project Requirements

As the Solution Architect, you are tasked with designing a scalable, resilient, and high-performing IoT-based monitoring and control solution for WAT. Your assessment should demonstrate capability across the following areas:

### Network Requirements

Design a communication network that can support:
- 1 million+ battery-operated IoT water meters, deployed across urban and semi-urban areas
- Remote valve control (on/off) capabilities
- Integration with existing SCADA systems
- Low-power, long-range connectivity
- Secure and 99.9% available network architecture

**Considerations:**
- Choice of connectivity technologies
- Gateway and edge processing strategy
- Redundancy, fault tolerance, and failover mechanisms

### Solution Requirements

The overall solution should include an application layer that can:
- Collect and store high-frequency sensor data
- Enable real-time valve control with low latency
- Perform data analytics for water quality and usage patterns

The solution must integrate with:
- SCADA systems
- Regulatory reporting platforms
- Dashboard and visualization tools

**Considerations:**
- Protocols
- Security mechanisms
- Integration and remote management

### Data Volume & Performance Requirements

The system design should have capacity for:
- Handling data from 1 million meters (with estimated sampling frequency)
- Ingesting, storing, processing, and archiving large volumes of time-series data

**Considerations:**
- Scalability of backend services
- Data lifecycle and retention policies

### Solution Constraints

- High availability (99.9%)
- Latency limits for control signals: <2 seconds for valve action
  - Critical for operation during emergencies or natural disasters
- Mandatory security layers
- Device and platform scalability
- Robust reporting feature enabling the Executive team to monitor real-time KPIs at any given moment

## Deliverables

### Architecture Document

- **High-Level Design Diagram** (Required)
- **Design Justification** (Required)
- **Low-Level Diagram** (Optional)

## Evaluation Criteria

- **Clarity of design**
- **Scalability and feasibility**
- **Innovation in network and data strategy**
- **Adherence to non-functional requirements**
- **Quality of documentation and HLD diagram**

---

*Note: This README outlines the requirements for the WAT project. The Solution Architect is expected to create the architecture documentation and design diagrams as specified in the deliverables section.*