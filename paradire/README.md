# Pan-Canada Immunization Data on Federated Data Architecture

## A. Objectives
- Federated data analytics with PT-level local analytics service platforms
- Federated data analytics on select population-level data in continuous event streams
- Distributed computational data joint-governance

&nbsp;

## B. Description
- Generating a set of synthetic patient population - EHRs with detailed events (encounters, prescriptions, procedures, vaccinations, etc) fully respecting Canadian demographics (population, location, gender, race, living conditions, etc)
- Establishing 13 computing clusters on GCP, each for a PT jurisdiction
	+ Each cluster hosts its EHRs in some HAPI FHIR server(s)
	+ A local analytics service platform: 
		* Data Governance Gateway (DGG):
			- configured with a set of machine-readable data standards for ESG
			- configured with a set of machine-executable data governance policy for ACG
			- monitoring system status, track lineage, and audit operations
		* Event Streaming Gateway (ESG): 
			- turn EHR vaccination events into streams based on instructions from DGG
			- perform in-stream processing instructions (querying, aggregation, filtering)
		* Local Analytics Pipeline (LAP):
			- receiving feredrated data analytics request, performing request, produces results.
		* Access Control Gateway (ACG):
			- receives request via a federated data analytics protocol/API, execute data governance policy on the request, forward it to LAP if compliant, 
			- receives response from LAP, execute data governance policy on the response, forward it to the requestor.
- Establishing 1 computing cluster on GCP for federal
	+ A federated analytics service platform:
		* Data Governance Gateway (DGG):
			- configured with a set of federated data analytics requests
			- configured with a set of population-level event stream analytics
			- monitoring system status, track lineage, and audit operations
		* Federated Analytics Pipeline (FAP):
			- creates feredrated data analytics request, delivers requests to PT, aggregates and produces results.
			- creates queries for vaccination with Adverse Effects, performs analytics, and produces results

&nbsp;

## C. Architecture

![Architecture Diagram](./img/system-architecture.drawio.svg)

&nbsp;