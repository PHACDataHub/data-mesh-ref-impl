# [Pan-Canada Immunization Data on Federated Data Architecture](#pan-canada-immunization-data-on-federated-data-architecture)

&nbsp;

Pan-Canada Immunization Data on Federated Data Architecture (in brief PARADIRE) is the $6^{\text{th}}$ milestone in **the ongoing journey to the Federated Data Architecture**, built by DMIA.

It is both a reference implementation and proof-of-concept, rather the latter, for showcasing the ability:
- for the Province or Territory (in brief PT) to *enable sharing its patient population vaccination related information* in particular and some other health information in general with the Federal government (in brief F):
    + within *a managed cloud fully under control of PT*, called the `PT Analytics Platform (PAP)`, which is *protected by required security measures*,
- for F to send conformant Federated Analytics Queries from the `Federal Analytics Platform (FAP)` and receives results from the PT under *joint data-governance policies* established and exercised by both PT and F, that
    + allows extraction of only certain information from PT information systems,
    + permits *valid set of analytics queries* coming from F to be executes, and
    + *control types and content of the result* of the queries to be sent to F.

&nbsp;

How to read this document:
- Part I - [The Proof-of-Concept (PoC)](./part-i.md):
    + First with an overview, then the present challenges, follow by the PoC guiding principles, its conceptual, and ends with key considerations.
    + This is a high-level walkthrough discussing multiple aspects of both the current situation and the PoC.
    + The target audience consists of key stake-holders, domain experts, project managers, architects, and others.
- Part II - [Access Control Gateway](./part-ii.md):
    + Discusses in detail Access Control Gateway, one of the key component of the PoC.
    + This is a technology-focus with proper details in both design and implementation aspects.
    + Architects, developers, devops engineers, and others with similar interests are the target audience.
- Part III - [PT and F clusters in harmony](/part-iii.md)
    + Provides a deep dive into the deployment of 13 PT clusters and 1 F clusters.
    + Utilization of modern cloud-native technologies such as containerization, orchestration, cloud-deployment, etc is omnipresent. 
    + The target audience includes, but not limited to, project managers, architects, devops engineers, and others.
- Part IV - [Looking forward with hindsight](./part-iv.md)
    + Review of what have been done, what can be improved, and what are missing.
    + Paradire Playground as the continuation of the PoC.

&nbsp;

## Table of Content
### I. [The Proof-of-Concept](./part-i.md)
### II. [What's underneath?](./part-ii.md)
### III. [PT and F clusters in harmony](/part-iii.md)
### IV. [Looking forward with hindsight](./part-iv.md)

--- 

&nbsp;

**dire** | ˈdī(ə)r |
- adjective:
    + (of a situation or event) extremely serious or urgent: *dire consequences*.
    + (of a warning or threat) presaging disaster: *dire warnings about breathing the fumes*
- (Latin) **dirus** ‘fearful, threatening’.
- $lev(paradire, paradise) = 1,$ where $lev(a,b)$ is the [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance) between two strings $a, b.$

&nbsp;

[Back to PHACDataHub/data-mesh-ref-impl](https://github.com/PHACDataHub/data-mesh-ref-impl)