/* eslint-disable no-template-curly-in-string */
const connectors: KafkaConnector<KafkaSourceConnectorFields>[] = [
  // {
  //   class: 'io.confluent.connect.jdbc.JdbcSinkConnector',
  //   label: 'JdbcSinkConnector',
  // },
  // {
  //   class: 'streams.kafka.connect.sink.Neo4jSinkConnector',
  //   label: 'Neo4jSinkConnector',
  // },
  // {
  //   class:
  //     'com.github.jcustenborder.kafka.connect.spooldir.SpoolDirAvroSourceConnector',
  //   label: 'SpoolDirAvroSourceConnector',
  // },
  // {
  //   class:
  //     'com.github.jcustenborder.kafka.connect.spooldir.SpoolDirBinaryFileSourceConnector',
  //   label: 'SpoolDirBinaryFileSourceConnector',
  // },
  {
    class:
      'io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector',
    label: 'File Pulse',
    suggestedOptions: [
      'name',
      'topic',
      'tasks.max',
      'fs.listing.class',
      'fs.listing.filters',
      'fs.listing.interval.ms',
      'fs.listing.task.delegation.enabled',
      'fs.cleanup.policy.class',
      'fs.cleanup.policy.triggered.on',
      'max.scheduled.files',
      'allow.tasks.reconfiguration.after.timeout.ms',
      'task.partitioner.class',
      'tasks.halt.on.error',
      'tasks.file.processing.order.by',
      'tasks.empty.poll.wait.ms',
      'ignore.committed.offsets',
      'value.connect.schema',
      'filters',
      'filters.${key}',
      'tasks.reader.class',
      'offset.policy.class',
      'tasks.file.status.storage.class',
      'tasks.file.status.storage.topic',
      'tasks.file.status.storage.bootstrap.servers',
      'tasks.file.status.storage.topic.partitions',
      'tasks.file.status.storage.topic.replication.factor'
    ],
    configuration: [
      {
        label: 'General',
        options: [
          {
            name: 'name',
            description: 'The name to assign this connector.',
            required: true,
            type: 'STRING',
          },
          {
            name: 'topic',
            description: 'The default output topic to write',
            required: true,
            type: 'STRING',
          },
          {
            name: 'tasks.max',
            description:
              'The maximum number of tasks that should be created for this connector.',
            type: 'STRING',
          },
        ],
      },
      {
        label: 'Filesystem Listing',
        options: [
          {
            name: 'fs.listing.class',
            description:
              'Class which is used to list eligible files from the scanned file system.',
            type: 'STRING',
          },
          {
            name: 'fs.listing.filters',
            description: 'Filters use to list eligible input files',
            type: 'LIST',
          },
          {
            name: 'fs.listing.interval.ms',
            description:
              'Time interval (in milliseconds) at wish to scan input directory',
            type: 'LONG',
            default: 10000,
          },
          {
            name: 'fs.listing.task.delegation.enabled',
            description:
              'Boolean indicating whether the file listing process should be delegated to tasks.',
            type: 'BOOLEAN',
            default: false,
          },
          {
            name: 'fs.cleanup.policy.class',
            description:
              'The fully qualified name of the class which is used to cleanup files',
            type: 'STRING',
          },
          {
            name: 'fs.cleanup.policy.triggered.on',
            description: 'Specify the status when a file get cleanup.',
            type: 'CHOICE',
            choices: ['COMPLETED', 'COMMITTED'],
            default: 'COMPLETED',
          },
          {
            name: 'max.scheduled.files',
            description:
              'Maximum number of files that can be schedules to tasks.',
            type: 'LONG',
            default: 1000,
          },
          {
            name: 'allow.tasks.reconfiguration.after.timeout.ms',
            description:
              'Specify the timeout (in milliseconds) for the connector to allow tasks to be reconfigured when new files are detected, even if some tasks are still being processed.',
            type: 'LONG',
          },
          {
            name: 'task.partitioner.class',
            description:
              'The TaskPartitioner to be used for partitioning files to tasks.',
            type: 'STRING',
            default:
              'io.streamthoughts.kafka.connect.filepulse.source.DefaultTaskPartitioner',
          },
          {
            name: 'tasks.halt.on.error',
            description:
              'Should a task halt when it encounters an error or continue to the next file.',
            type: 'BOOLEAN',
            default: false,
          },
          {
            name: 'tasks.file.processing.order.by',
            description:
              'The strategy to be used for sorting files for processing.',
            type: 'CHOICE',
            choices: [
              'LAST_MODIFIED',
              'URI',
              'CONTENT_LENGTH',
              'CONTENT_LENGTH_DESC',
            ],
            default: 'LAST_MODIFIED',
          },
          {
            name: 'tasks.empty.poll.wait.ms',
            description:
              'The amount of time in millisecond a tasks should wait if a poll returns an empty list of records.',
            type: 'LONG',
            default: 500,
          },
          {
            name: 'ignore.committed.offsets',
            description:
              'Should a task ignore committed offsets while scheduling a file.',
            type: 'BOOLEAN',
            default: false,
          },
          {
            name: 'value.connect.schema',
            description: 'The schema for the record-value.',
            type: 'STRING',
          },
          {
            name: 'fs.listing.directory.path',
            description: 'The input directory to scan string',
            type: 'STRING',
          },
          {
            name: 'fs.listing.recursive.enabled',
            description:
              'Flag indicating whether local directory should be recursively scanned',
            type: 'BOOLEAN',
            default: true,
          },
          {
            name: 'file.filter.regex.pattern',
            description:
              'The RegexFileFilter can be used to filter all files that do not match the specified regex.',
            type: 'STRING',
          },
          {
            name: 'offset.strategy',
            description:
              'A separated list of attributes, using + as a character separator, to be used for uniquely identifying an input file; must be one of [name, path, lastModified, inode, hash] (e.g: name+hash). Note that order doesn’t matter',
            type: 'STRING',
          },
        ],
      },
      {
        label: 'File Reader',
        options: [
          {
            name: 'tasks.reader.class',
            type: 'STRING',
            description:
              'The fully qualified name of the class which is used by tasks to read input files',
          },
          {
            name: 'offset.policy.class',
            description:
              'Class which is used to determine the source partition and offset that uniquely identify a input record',
            default:
              'io.streamthoughts.kafka.connect.filepulse.offset.DefaultSourceOffsetPolicy',
            type: 'STRING',
          },
        ],
      },
      {
        label: 'XxxXMLFileInputReader ',
        options: [
          {
            name: 'reader.xpath.expression',
            description:
              'The XPath expression used extract data from XML input files',
            type: 'STRING',
          },
          {
            name: 'reader.xpath.result.type',
            description: 'The expected result type for the XPath expression',
            type: 'CHOICE',
            choices: ['NODESET', 'STRING'],
            default: 'NODESET',
          },
          {
            name: 'reader.xml.force.array.on.fields',
            description:
              'The comma-separated list of fields for which an array-type must be forced',
            type: 'LIST',
          },
          {
            name: 'reader.xml.parser.validating.enabled',
            description:
              'Specifies that the parser will validate documents as they are parsed.',
            type: 'BOOLEAN',
            default: false,
          },
          {
            name: 'reader.xml.parser.namespace.aware.enabled',
            description:
              'Specifies that the XML parser will provide support for XML namespaces.',
            type: 'BOOLEAN',
            default: false,
          },
          {
            name: 'reader.xml.exclude.empty.elements',
            description:
              'Specifies that the reader should exclude element having no field.',
            type: 'BOOLEAN',
            default: false,
          },
          {
            name: 'reader.xml.exclude.node.attributes',
            description:
              'Specifies that the reader should exclude all node attributes.',
            type: 'BOOLEAN',
            default: false,
          },
          {
            name: 'reader.xml.exclude.node.attributes.in.namespaces',
            description:
              'Specifies that the reader should only exclude node attributes in the defined list of namespaces.',
            type: 'LIST',
          },
          {
            name: 'reader.xml.data.type.inference.enabled',
            description:
              'Specifies that the reader should try to infer the type of data nodes.',
            type: 'BOOLEAN',
            default: false,
          },
          {
            name: 'reader.xml.attribute.prefix',
            description:
              'If set, the name of attributes will be prepended with the specified prefix when they are added to a record.',
            type: 'STRING',
          },
          {
            name: 'reader.xml.content.field.name',
            description:
              'Specifies the name to be used for naming the field that will contain the value of a TextNode element having attributes.',
            type: 'STRING',
          },
          {
            name: 'reader.xml.field.name.characters.regex.pattern',
            description:
              'Specifies the regex pattern to use for matching the characters in XML element name to replace when converting a document to a struct.',
            type: 'STRING',
          },
          {
            name: 'reader.xml.field.name.characters.string.replacement',
            description:
              'Specifies the replacement string to be used when converting a document to a struct.',
            type: 'STRING',
          },
          {
            name: 'reader.xml.force.content.field.for.paths',
            description:
              'The comma-separated list of field for which a content-field must be forced.',
            type: 'LIST',
          },
        ],
      },
      {
        label: 'Filter Chain Definition',
        options: [
          {
            name: 'filters',
            description:
              'List of aliases for the filter, specifying the order in which the filters will be applied.',
            type: 'LIST',
          },
          {
            name: 'filters.${key}',
            description: 'Configuration properties for the filter(s).',
            type: 'JSONBUILDER',
            multiple: true,
          },
        ],
      },
      {
        label: 'Synchronizing connector and tasks',
        options: [
          {
            name: 'tasks.file.status.storage.class',
            type: 'CHOICE',
            default:
              'io.streamthoughts.kafka.connect.filepulse.state.KafkaFileObjectStateBackingStore',
            choices: [
              'io.streamthoughts.kafka.connect.filepulse.state.KafkaFileObjectStateBackingStore',
              'io.streamthoughts.kafka.connect.filepulse.state.InMemoryFileObjectStateBackingStore',
            ],
            description:
              'The FileObjectStateBackingStore class to be used for storing status state of file objects.',
          },
        ],
      },
      {
        label: 'KafkaFileObjectStateBackingStore',
        options: [
          {
            name: 'tasks.file.status.storage.topic',
            description:
              'Name of the internal topic used by tasks and connector to report and monitor file progression.',
            type: 'STRING',
          },
          {
            name: 'tasks.file.status.storage.bootstrap.servers',
            description:
              'A list of host/port pairs uses by the reporter for establishing the initial connection to the Kafka cluster.',
            type: 'STRING',
          },
          {
            name: 'tasks.file.status.storage.topic.partitions',
            description:
              'The number of partitions to be used for the status storage topic.',
            type: 'INT',
          },
          {
            name: 'tasks.file.status.storage.topic.replication.factor',
            description:
              'The replication factor to be used for the status storage topic.',
            type: 'LONG',
          },
        ],
      },
    ],
  },
  {
    class:
      'com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector',
    label: 'SpoolDirCsvSourceConnector',
    suggestedOptions: [
      'topic',
      'input.path',
      'finished.path',
      'error.path',
      'input.file.pattern',
      'schema.generation.enabled',
      'schema.generation.key.fields',
      'csv.first.row.as.header',
    ],
    configuration: [
      {
        label: 'General',
        options: [
          {
            name: 'topic',
            description: 'The Kafka topic to write the data to.',

            required: true,

            type: 'STRING',
          },
          {
            name: 'batch.size',
            description:
              'The number of records that should be returned with each batch.',
            type: 'INT',

            default: 1000,
          },
          {
            name: 'csv.case.sensitive.field.names',
            description:
              'Flag to determine if the field names in the header row should be treated as case sensitive.',
            type: 'BOOLEAN',
          },
          {
            name: 'csv.rfc.4180.parser.enabled',
            description:
              'Flag to determine if the RFC 4180 parser should be used instead of the default parser.',
            type: 'BOOLEAN',
          },
          {
            name: 'empty.poll.wait.ms',
            description:
              'The amount of time to wait if a poll returns an empty list of records.',
            type: 'LONG',

            default: 500,
          },
          {
            name: 'task.count',
            description:
              'Internal setting to the connector used to instruct a task on which files to select. The connector will override this setting.',
            type: 'INT',

            default: 1,
          },
          {
            name: 'task.index',
            description:
              'Internal setting to the connector used to instruct a task on which files to select. The connector will override this setting.',
            type: 'INT',

            default: 0,
          },
        ],
      },
      {
        label: 'File System',
        options: [
          {
            name: 'error.path',
            description:
              'The directory to place files in which have error(s). This directory must exist and be writable by the user running Kafka Connect.',
            required: true,
            type: 'STRING',
          },
          {
            name: 'input.file.pattern',
            description:
              'Regular expression to check input file names against. This expression must match the entire filename. The equivalent of Matcher.matches().',
            required: true,
            type: 'STRING',
          },
          {
            name: 'input.path',
            description:
              'The directory to read files that will be processed. This directory must exist and be writable by the user running Kafka Connect.',

            required: true,
            type: 'STRING',
          },
          {
            name: 'finished.path',
            description:
              'The directory to place files that have been successfully processed. This directory must exist and be writable by the user running Kafka Connect.',

            required: true,

            type: 'STRING',
          },
          {
            name: 'halt.on.error',
            description:
              'Should the task halt when it encounters an error or continue to the next file.',

            required: true,

            type: 'BOOLEAN',

            default: true,
          },
          {
            name: 'cleanup.policy',
            description:
              'Determines how the connector should cleanup the files that have been successfully processed. NONE leaves the files in place which could cause them to be reprocessed if the connector is restarted. DELETE removes the file from the filesystem. MOVE will move the file to a finished directory. MOVEBYDATE will move the file to a finished directory with subdirectories by date',
            type: 'CHOICE',
            default: 'MOVE',
            choices: ['NONE', 'DELETE', 'MOVE', 'MOVEBYDATE'],
          },
          {
            name: 'task.partitioner',
            description:
              'The task partitioner implementation is used when the connector is configured to use more than one task. This is used by each task to identify which files will be processed by that task. This ensures that each file is only assigned to one task.',
            type: 'CHOICE',
            default: 'ByName',
            choices: ['ByName'],
          },
          {
            name: 'file.buffer.size.bytes',
            description:
              'The size of buffer for the BufferedInputStream that will be used to interact with the file system.',
            type: 'INT',

            default: 131072,
          },
          {
            name: 'file.minimum.age.ms',
            description:
              'The amount of time in milliseconds after the file was last written to before the file can be processed.',
            type: 'LONG',

            default: 0,
          },
          {
            name: 'files.sort.attributes',
            description:
              'The attributes each file will use to determine the sort order. Name is name of the file. Length is the length of the file preferring larger files first. LastModified is the LastModified attribute of the file preferring older files first.',
            type: 'LIST',

            default: ['NameAsc'],

            listItems: [
              'NameAsc',
              'NameDesc',
              'LengthAsc',
              'LengthDesc',
              'LastModifiedAsc',
              'LastModifiedDesc',
            ],
          },
          {
            name: 'processing.file.extension',
            description:
              'Before a file is processed, a flag is created in its directory to indicate the file is being handled. The flag file has the same name as the file, but with this property appended as a suffix.',
            type: 'STRING',

            default: '.PROCESSING',
          },
        ],
      },
      {
        label: 'Schema',
        options: [
          {
            name: 'key.schema',
            description: 'The schema for the key written to Kafka.',

            required: true,

            type: 'STRING',
          },
          {
            name: 'value.schema',
            description: 'The schema for the value written to Kafka.',

            required: true,

            type: 'STRING',
          },
        ],
      },
      {
        label: 'CSV Parsing',
        options: [
          {
            name: 'csv.first.row.as.header',
            description:
              'Flag to indicate if the fist row of data contains the header of the file. If true the position of the columns will be determined by the first row to the CSV. The column position will be inferred from the position of the schema supplied in value.schema. If set to true the number of columns must be greater than or equal to the number of fields in the schema.',
            type: 'BOOLEAN',
          },
          {
            name: 'csv.escape.char',
            description:
              'The character as an integer to use when a special character is encountered. The default escape character is typically a (92)',
            type: 'INT',

            default: 92,
          },
          {
            name: 'csv.file.charset',
            description: 'Character set to read wth file with.',
            type: 'CHOICE',

            default: 'UTF-8',

            choices: [
              'Big5',
              'Big5-HKSCS',
              'CESU-8',
              'EUC-JP',
              'EUC-KR',
              'GB18030',
              'GB2312',
              'GBK',
              'IBM-Thai',
              'IBM00858',
              'IBM01140',
              'IBM01141',
              'IBM01142',
              'IBM01143',
              'IBM01144',
              'IBM01145',
              'IBM01146',
              'IBM01147',
              'IBM01148',
              'IBM01149',
              'IBM037',
              'IBM1026',
              'IBM1047',
              'IBM273',
              'IBM277',
              'IBM278',
              'IBM280',
              'IBM284',
              'IBM285',
              'IBM290',
              'IBM297',
              'IBM420',
              'IBM424',
              'IBM437',
              'IBM500',
              'IBM775',
              'IBM850',
              'IBM852',
              'IBM855',
              'IBM857',
              'IBM860',
              'IBM861',
              'IBM862',
              'IBM863',
              'IBM864',
              'IBM865',
              'IBM866',
              'IBM868',
              'IBM869',
              'IBM870',
              'IBM871',
              'IBM918',
              'ISO-2022-CN',
              'ISO-2022-JP',
              'ISO-2022-JP-2',
              'ISO-2022-KR',
              'ISO-8859-1',
              'ISO-8859-13',
              'ISO-8859-15',
              'ISO-8859-16',
              'ISO-8859-2',
              'ISO-8859-3',
              'ISO-8859-4',
              'ISO-8859-5',
              'ISO-8859-6',
              'ISO-8859-7',
              'ISO-8859-8',
              'ISO-8859-9',
              'JIS_X0201',
              'JIS_X0212-1990',
              'KOI8-R',
              'KOI8-U',
              'Shift_JIS',
              'TIS-620',
              'US-ASCII',
              'UTF-16',
              'UTF-16BE',
              'UTF-16LE',
              'UTF-32',
              'UTF-32BE',
              'UTF-32LE',
              'UTF-8',
              'windows-1250',
              'windows-1251',
              'windows-1252',
              'windows-1253',
              'windows-1254',
              'windows-1255',
              'windows-1256',
              'windows-1257',
              'windows-1258',
              'windows-31j',
              'x-Big5-HKSCS-2001',
              'x-Big5-Solaris',
              'x-euc-jp-linux',
              'x-EUC-TW',
              'x-eucJP-Open',
              'x-IBM1006',
              'x-IBM1025',
              'x-IBM1046',
              'x-IBM1097',
              'x-IBM1098',
              'x-IBM1112',
              'x-IBM1122',
              'x-IBM1123',
              'x-IBM1124',
              'x-IBM1129',
              'x-IBM1166',
              'x-IBM1364',
              'x-IBM1381',
              'x-IBM1383',
              'x-IBM29626C',
              'x-IBM300',
              'x-IBM33722',
              'x-IBM737',
              'x-IBM833',
              'x-IBM834',
              'x-IBM856',
              'x-IBM874',
              'x-IBM875',
              'x-IBM921',
              'x-IBM922',
              'x-IBM930',
              'x-IBM933',
              'x-IBM935',
              'x-IBM937',
              'x-IBM939',
              'x-IBM942',
              'x-IBM942C',
              'x-IBM943',
              'x-IBM943C',
              'x-IBM948',
              'x-IBM949',
              'x-IBM949C',
              'x-IBM950',
              'x-IBM964',
              'x-IBM970',
              'x-ISCII91',
              'x-ISO-2022-CN-CNS',
              'x-ISO-2022-CN-GB',
              'x-iso-8859-11',
              'x-JIS0208',
              'x-JISAutoDetect',
              'x-Johab',
              'x-MacArabic',
              'x-MacCentralEurope',
              'x-MacCroatian',
              'x-MacCyrillic',
              'x-MacDingbat',
              'x-MacGreek',
              'x-MacHebrew',
              'x-MacIceland',
              'x-MacRoman',
              'x-MacRomania',
              'x-MacSymbol',
              'x-MacThai',
              'x-MacTurkish',
              'x-MacUkraine',
              'x-MS932_0213',
              'x-MS950-HKSCS',
              'x-MS950-HKSCS-XP',
              'x-mswin-936',
              'x-PCK',
              'x-SJIS_0213',
              'x-UTF-16LE-BOM',
              'X-UTF-32BE-BOM',
              'X-UTF-32LE-BOM',
              'x-windows-50220',
              'x-windows-50221',
              'x-windows-874',
              'x-windows-949',
              'x-windows-950',
              'x-windows-iso2022jp',
            ],
          },
          {
            name: 'csv.ignore.leading.whitespace',
            description:
              'Sets the ignore leading whitespace setting - if true - white space in front of a quote in a field is ignored.',
            type: 'BOOLEAN',

            default: true,
          },
          {
            name: 'csv.ignore.quotations',
            description:
              'Sets the ignore quotations mode - if true, quotations are ignored.',
            type: 'BOOLEAN',
          },
          {
            name: 'csv.keep.carriage.return',
            description:
              'Flag to determine if the carriage return at the end of the line should be maintained.',
            type: 'BOOLEAN',
          },
          {
            name: 'csv.null.field.indicator',
            description:
              'Indicator to determine how the CSV Reader can determine if a field is null. Valid values are EMPTY_SEPARATORS, EMPTY_QUOTES, BOTH, NEITHER. For more information see http://opencsv.sourceforge.net/apidocs/com/opencsv/enums/CSVReaderNullFieldIndicator.html.',
            type: 'CHOICE',

            default: 'NEITHER',

            choices: ['EMPTY_SEPARATORS', 'EMPTY_QUOTES', 'BOTH', 'NEITHER'],
          },
          {
            name: 'csv.quote.char',
            description:
              'The character that is used to quote a field. This typically happens when the csv.separator.char character is within the data.',
            type: 'INT',

            default: 34,
          },
          {
            name: 'csv.separator.char',
            description:
              'The character that separates each field in the form of an integer. Typically in a CSV this is a ,(44) character. A TSV would use a tab(9) character. If csv.separator.char is defined as a null(0), then the RFC 4180 parser must be utilized by default. This is the equivalent of csv.rfc.4180.parser.enabled = true.',
            type: 'INT',

            default: 44,
          },
          {
            name: 'csv.skip.lines',
            description:
              'Number of lines to skip in the beginning of the file.',
            type: 'INT',

            default: 0,
          },
          {
            name: 'csv.strict.quotes',
            description:
              'Sets the strict quotes setting - if true, characters outside the quotes are ignored.',
            type: 'BOOLEAN',
          },
          {
            name: 'csv.verify.reader',
            description: 'Flag to determine if the reader should be verified.',
            type: 'BOOLEAN',

            default: true,
          },
        ],
      },
      {
        label: 'Schema Generation',
        options: [
          {
            name: 'schema.generation.enabled',
            description:
              'Flag to determine if schemas should be dynamically generated. If set to true, key.schema and value.schema can be omitted, but schema.generation.key.name and schema.generation.value.name must be set.',
            type: 'BOOLEAN',
          },
          {
            name: 'schema.generation.key.fields',
            description:
              'The field(s) to use to build a key schema. This is only used during schema generation.',
            type: 'LIST',
          },
          {
            name: 'schema.generation.key.name',
            description: 'The name of the generated key schema.',
            type: 'STRING',

            default: 'com.github.jcustenborder.kafka.connect.model.Key',
          },
          {
            name: 'schema.generation.value.name',
            description: 'The name of the generated value schema.',
            type: 'STRING',

            default: 'com.github.jcustenborder.kafka.connect.model.Value',
          },
        ],
      },
      {
        label: 'Timestamps',
        options: [
          {
            name: 'timestamp.field',
            description:
              'The field in the value schema that will contain the parsed timestamp for the record. This field cannot be marked as optional and must be a Timestamp',
            type: 'STRING',
          },
          {
            name: 'timestamp.mode',
            description:
              'Determines how the connector will set the timestamp for the ConnectRecord. If set to Field then the timestamp will be read from a field in the value. This field cannot be optional and must be a Timestamp. Specify the field in timestamp.field. If set to FILE_TIME then the last modified time of the file will be used. If set to PROCESS_TIME the time the record is read will be used.',
            type: 'CHOICE',

            default: 'PROCESS_TIME',

            choices: ['FIELD', 'FILE_TIME', 'PROCESS_TIME'],
          },
          {
            name: 'parser.timestamp.date.formats',
            description:
              'The date formats that are expected in the file. This is a list of strings that will be used to parse the date fields in order. The most accurate date format should be the first in the list. Take a look at the Java documentation for more info. https://docs.oracle.com/javase/6/docs/api/java/text/SimpleDateFormat.html',
            type: 'LIST',

            default: ["yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd' 'HH:mm:ss"],
          },
          {
            name: 'parser.timestamp.timezone',
            description:
              'The timezone that all of the dates will be parsed with.',
            type: 'STRING',

            default: 'UTC',
          },
        ],
      },
    ],
  },
  {
    class:
      'com.github.jcustenborder.kafka.connect.spooldir.SpoolDirJsonSourceConnector',
    label: 'SpoolDirJsonSourceConnector',
    disabled: true,
  },
  // {
  //   class:
  //     'com.github.jcustenborder.kafka.connect.spooldir.SpoolDirLineDelimitedSourceConnector',
  //   label: 'SpoolDirLineDelimitedSourceConnector',
  // },
  // {
  //   class:
  //     'com.github.jcustenborder.kafka.connect.spooldir.SpoolDirSchemaLessJsonSourceConnector',
  //   label: 'SpoolDirSchemaLessJsonSourceConnector',
  // },
  // {
  //   class:
  //     'com.github.jcustenborder.kafka.connect.spooldir.elf.SpoolDirELFSourceConnector',
  //   label: 'SpoolDirELFSourceConnector',
  // },
  // {
  //   class: 'io.confluent.connect.jdbc.JdbcSourceConnector',
  //   label: 'JdbcSourceConnector',
  // },
  // {
  //   class: 'io.debezium.connector.mysql.MySqlConnector',
  //   label: 'MySqlConnector',
  // },
  // {
  //   class: 'org.apache.kafka.connect.mirror.MirrorCheckpointConnector',
  //   label: 'MirrorCheckpointConnector',
  // },
  // {
  //   class: 'org.apache.kafka.connect.mirror.MirrorHeartbeatConnector',
  //   label: 'MirrorHeartbeatConnector',
  // },
  // {
  //   class: 'org.apache.kafka.connect.mirror.MirrorSourceConnector',
  //   label: 'MirrorSourceConnector',
  // },
  // {
  //   class: 'streams.kafka.connect.source.Neo4jSourceConnector',
  //   label: 'Neo4jSourceConnector',
  // },
]

export default connectors
