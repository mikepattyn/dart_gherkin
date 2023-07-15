import 'gherkin/attachments/attachment_manager.dart';
import 'gherkin/parameters/custom_parameter.dart';
import 'gherkin/steps/step_definition.dart';
import 'gherkin/steps/world.dart';
import 'hooks/hook.dart';
import 'io/feature_file_matcher.dart';
import 'io/feature_file_reader.dart';
import 'io/io_feature_file_accessor.dart';
import 'reporters/json/json_reporter.dart';
import 'reporters/message_level.dart';
import 'reporters/progress_reporter.dart';
import 'reporters/reporter.dart';
import 'reporters/stdout_reporter.dart';
import 'reporters/test_run_summary_reporter.dart';

typedef CreateWorld = Future<World> Function(TestConfiguration config);
typedef CreateAttachmentManager = Future<AttachmentManager> Function(
  TestConfiguration config,
);

enum ExecutionOrder { sequential, random, alphabetical }

class TestConfiguration {
  /// The path(s) to all the features.
  /// All three [Pattern]s are supported: [RegExp], [String], [Glob].
  Iterable<Pattern> features;

  /// The default feature language
  String featureDefaultLanguage;

  /// a filter to limit the features that are run based on tags
  /// see https://docs.cucumber.io/cucumber/tag-expressions/ for expression syntax
  String? tagExpression;

  /// The default step timeout - this can be override when definition a step definition
  Duration defaultTimeout;

  /// The execution order of features - this default to random to avoid any inter-test dependencies
  ExecutionOrder order;

  /// The user defined step definitions that are matched with written steps in the features
  Iterable<StepDefinitionGeneric>? stepDefinitions;

  /// Any user defined step parameters
  Iterable<CustomParameter<dynamic>>? customStepParameterDefinitions;

  /// Hooks that are run at certain points in the execution cycle
  Iterable<Hook>? hooks;

  /// a list of reporters to use.
  /// Built-in reporters:
  ///   - StdoutReporter
  ///   - ProgressReporter
  ///   - TestRunSummaryReporter
  ///   - JsonReporter
  /// Custom reporters can be created by implementing [Reporter]
  Iterable<Reporter> reporters;

  /// An optional function to create a world object for each scenario.
  CreateWorld? createWorld;

  // Lists feature files paths, which match [features] patterns.
  FeatureFileMatcher featureFileMatcher;

  // The feature file reader.
  // Takes files/resources paths from [featureFileIndexer] and returns their content as String.
  FeatureFileReader featureFileReader;

  /// the program will stop after any test failed
  bool stopAfterTestFailed;

  /// When a step fails, it will retry this number of times.
  /// When it still fails after these tries the step will fail.
  int stepMaxRetries;

  /// When a step fails, it will wait this long before retrying.
  /// For instance, you know that when it fails, it can take a bit longer (async).
  Duration retryDelay;

  TestConfiguration({
    this.features = const <Pattern>[],
    this.featureDefaultLanguage = 'en',
    this.order = ExecutionOrder.random,
    this.defaultTimeout = const Duration(seconds: 10),
    this.featureFileMatcher = const IoFeatureFileAccessor(),
    this.featureFileReader = const IoFeatureFileAccessor(),
    this.stopAfterTestFailed = false,
    this.tagExpression,
    this.stepDefinitions,
    this.customStepParameterDefinitions,
    this.hooks,
    this.reporters = const [],
    this.createWorld,
    this.stepMaxRetries = 0,
    this.retryDelay = const Duration(seconds: 2),
  });

  /// used to allow for custom configuration to ensure framework specific configuration is in place
  TestConfiguration prepare() => this;

  /// used to get a new instance of an attachment manager class that is passed to the World context
  CreateAttachmentManager get getAttachmentManager => (_) => Future.value(AttachmentManager());

  /// Provide a configuration object with default settings such as the reports and feature file location
  /// Additional setting on the configuration object can be set on the returned instance.
  TestConfiguration.standard(
    Iterable<StepDefinitionGeneric<World>> steps, {
    String featurePath = r'features\\.+\.feature',
    this.featureDefaultLanguage = 'en',
    this.order = ExecutionOrder.random,
    this.defaultTimeout = const Duration(seconds: 10),
    this.featureFileMatcher = const IoFeatureFileAccessor(),
    this.featureFileReader = const IoFeatureFileAccessor(),
    this.stopAfterTestFailed = false,
    this.tagExpression,
    this.customStepParameterDefinitions,
    this.hooks,
    this.createWorld,
    this.stepMaxRetries = 0,
    this.retryDelay = const Duration(seconds: 2),
  })  : features = [RegExp(featurePath)],
        reporters = [
          StdoutReporter(MessageLevel.error),
          ProgressReporter(),
          TestRunSummaryReporter(),
          JsonReporter(),
        ],
        stepDefinitions = steps;
}
