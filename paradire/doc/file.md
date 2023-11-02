<h1>FHIR Data Upload Scripts Documentation<h1>

**Overview**
The following documentation elucidates the structure and operation of scripts designed for uploading Electronic Health Records (EHRs), hospital details, and practitioner records to the FHIR server located at localhost:8080.

**Key Tools Utilized**
- GNU Parallel: A shell tool for executing jobs in parallel using one or more computers.
- jq: A lightweight and flexible command-line JSON processor.

**Script Structure**
1. Dependency Verification:
Each script begins by verifying the presence of required tools (GNU Parallel and jq). If absent, the script automatically installs the necessary tools.

2. Input Validation:
The script expects a valid province or territory abbreviation. A predefined list of valid inputs ensures accurate data targeting.

3. Data Upload Process:
The script identifies specific JSON files within the designated output directory.Utilizing GNU Parallel, the script concurrently initiates multiple upload tasks, significantly reducing the overall upload duration.

**Script Breakdown**
1. upload_EHRs.sh
Purpose: This script primarily manages the upload of general Electronic Health Records (excluding hospital and practitioner details).
File Targeting: It looks for JSON files within the designated output directory, specifically avoiding those named hospitalInformation* and practitionerInformation*.

2. upload_hospitals.sh
Purpose: This script focuses on uploading hospital-specific information.
File Targeting: Searches and uploads files named hospitalInformation*.json from the directory based on the provided province or territory abbreviation.

3. upload_practitioners.sh
Purpose: Dedicated to uploading practitioner-specific details.
File Targeting: This script pinpoints and uploads practitionerInformation*.json files.

**Performance Metrics**
Initial manual upload time for 100 records: 469 seconds.
Post-parallelization upload time for 100 records: 160 seconds.
Post-parallelization upload time for 10,000 records: 1342 seconds.

The application of GNU Parallel dramatically enhanced the efficiency of data upload tasks, evident from the substantial time savings in the metrics above.