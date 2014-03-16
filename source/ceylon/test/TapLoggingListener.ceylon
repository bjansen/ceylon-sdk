import ceylon.test.event { TestIgnoreEvent, TestFinishEvent, TestRunFinishEvent, TestRunStartEvent }

"A [[TestListener]] that prints information about test execution to a given logging function,
 in [Test Anything Protocol v13](http://testanything.org/tap-version-13-specification.html) format.
 
 ### YAML keys used
 
 * `elapsed` for the [[elapsed time|TestResult.elapsedTime]], in milliseconds (not for ignored tests)
 * `reason` for the [[ignore reason|IgnoreAnnotation.reason]], if present
 * `severity` for the [[state|TestResult.state]], one of `failure` or `error` (omitted for sucessful tests)
 * `actual`, `expected` if the [[exception|TestResult.exception]] is an [[AssertionComparisonException]]
 * `exception` for the exception’s stacktrace if it exists, but isn’t an [[AssertionComparisonException]].
 
 ### Example
 
 ~~~tap
 TAP version 13
 ok 1 - test.my.module::testFeature
   ---
   elapsed: 163
   ...
 not ok 2 - test.my.module::testOtherFeature
   ---
   elapsed: 11
   severity: failure
   actual: |
     Lorem ipsum dolor sit amet ,
     consetetur sadipscing elitr ,
     sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat ,
     sed diam voluptua .
   expected: |
     Lorem ipsum dolor sit amet,
     consetetur sadipscing elitr,
     sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat,
     sed diam voluptua.
   ...
 not ok 3 - test.my.module::testProposedFeature # SKIP ignored
   ---
   reason: not yet implemented
   ...
 not ok 4 - test.my.module::testBrokenFeature 
   ---
   elapsed: 15
   severity: error
   exception: |
     java.lang.Exception: Error
         at test.my.module.testBrokenFeature_.testBrokenFeature(testBrokenFeature.ceylon:3)
         at com.redhat.ceylon.compiler.java.runtime.metamodel.AppliedFunction.$call$(AppliedFunction.java:257)
         at com.redhat.ceylon.compiler.java.Util.apply(Util.java:934)
         at com.redhat.ceylon.compiler.java.runtime.metamodel.Metamodel.apply(Metamodel.java:1099)
         at com.redhat.ceylon.compiler.java.runtime.metamodel.AppliedFunction.apply(AppliedFunction.java:413)
         at com.redhat.ceylon.compiler.java.runtime.metamodel.FreeFunction.invoke(FreeFunction.java:262)
         at com.redhat.ceylon.compiler.java.runtime.metamodel.FreeFunction.invoke(FreeFunction.java:251)
         at com.redhat.ceylon.compiler.java.runtime.metamodel.FreeFunction.invoke(FreeFunction.java:244)
         at ceylon.test.internal.DefaultTestExecutor.invokeFunction$priv$(executors.ceylon:254)
         at ceylon.test.internal.DefaultTestExecutor.invokeTest$priv$(executors.ceylon:249)
         at ceylon.test.internal.DefaultTestExecutor.access$000(executors.ceylon:253)
         at ceylon.test.internal.DefaultTestExecutor$4.$call$(executors.ceylon)
         at ceylon.test.internal.DefaultTestExecutor$10.$call$(executors.ceylon:168)
         at ceylon.test.internal.DefaultTestExecutor$11.$call$(executors.ceylon:174)
         at ceylon.test.internal.DefaultTestExecutor$9.$call$(executors.ceylon:150)
         at ceylon.test.internal.DefaultTestExecutor$8.$call$(executors.ceylon:140)
         at ceylon.test.internal.DefaultTestExecutor$7.$call$(executors.ceylon:131)
         at ceylon.test.internal.DefaultTestExecutor$6.$call$(executors.ceylon:111)
         at ceylon.test.internal.DefaultTestExecutor$5.$call$(executors.ceylon:91)
         at ceylon.test.internal.DefaultTestExecutor.execute(executors.ceylon:61)
         at ceylon.test.internal.TestRunnerImpl.run(TestRunnerImpl.ceylon:49)
         at test.ceylon.formatter.run_.run(run.ceylon:4)
         at test.ceylon.formatter.run_.main(run.ceylon)
         at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
         at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
         at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
         at java.lang.reflect.Method.invoke(Method.java:606)
         at ceylon.modules.api.runtime.SecurityActions.invokeRunInternal(SecurityActions.java:58)
         at ceylon.modules.api.runtime.SecurityActions.invokeRun(SecurityActions.java:48)
         at ceylon.modules.api.runtime.AbstractRuntime.invokeRun(AbstractRuntime.java:85)
         at ceylon.modules.api.runtime.AbstractRuntime.execute(AbstractRuntime.java:145)
         at ceylon.modules.api.runtime.AbstractRuntime.execute(AbstractRuntime.java:129)
         at ceylon.modules.Main.execute(Main.java:69)
         at ceylon.modules.Main.main(Main.java:42)
         at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
         at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
         at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
         at java.lang.reflect.Method.invoke(Method.java:606)
         at org.jboss.modules.Module.run(Module.java:270)
         at org.jboss.modules.Main.main(Main.java:294)
         at ceylon.modules.bootstrap.CeylonRunTool.run(CeylonRunTool.java:208)
         at com.redhat.ceylon.common.tools.CeylonTool.run(CeylonTool.java:343)
         at com.redhat.ceylon.common.tools.CeylonTool.execute(CeylonTool.java:283)
         at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
         at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
         at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
         at java.lang.reflect.Method.invoke(Method.java:606)
         at com.redhat.ceylon.launcher.Launcher.run(Launcher.java:89)
         at com.redhat.ceylon.launcher.Launcher.main(Launcher.java:21)
   ...
 1..4
 ~~~"
shared class TapLoggingListener(write = print) satisfies TestListener {
    
    "A function that logs the given line, for example [[print]]."
    void write(String line);
    
    variable Integer count = 1;
    
    shared actual void testRunStart(TestRunStartEvent event)
            => write("TAP version 13");
    
    void testSomething(TestFinishEvent|TestIgnoreEvent event) {
        TestResult result;
        if (is TestFinishEvent event) {
            result = event.result;
        } else {
            assert (is TestIgnoreEvent event); // ceylon-spec#74
            result = event.result;
        }
        String okOrNotOk = result.state == success then "ok" else "not ok";
        String directive = result.state == ignored then "# SKIP ignored" else "";
        write("``okOrNotOk`` ``count`` - ``result.description.name`` `` directive``");
        
        // YAML
        Integer? elapsed = event is TestFinishEvent then result.elapsedTime;
        String? ignoreReason;
        if (is TestIgnoreEvent event) {
            ignoreReason = result.exception?.message;
        } else {
            ignoreReason = null;
        }
        String? severity = result.state == failure then "failure" else (result.state == error then "error");
        Exception? exception;
        if (is TestFinishEvent event) {
            exception = result.exception;
        } else {
            exception = null;
        }
        if (elapsed exists || ignoreReason exists || exception exists) {
            write("  ---");
            if (exists elapsed) {
                write("  elapsed: ``elapsed``");
            }
            if (exists ignoreReason) {
                write("  reason: ``ignoreReason``");
            }
            if (exists severity) {
                write("  severity: ``severity``");
            }
            if (exists exception) {
                if (is AssertionComparisonException exception) {
                    write("  actual: |");
                    for (line in exception.actualValue.replace("\r\n", "\n").split('\n'.equals)) {
                        write("    ``line``");
                    }
                    write("  expected: |");
                    for (line in exception.expectedValue.replace("\r\n", "\n").split('\n'.equals)) {
                        write("    ``line``");
                    }
                } else {
                    write("  exception: |");
                    printStackTrace(exception, void(String string) {
                        for (line in string.replace("\r\n", "\n").split('\n'.equals).filter((String s) => !s.empty)) {
                            write("    ``line.replace("\t", "    ")``");
                        }
                    });
                }
            }
            write("  ...");
        }
        
        count++;
    }
    
    shared actual void testFinish(TestFinishEvent event)
            => testSomething(event);
    
    shared actual void testIgnore(TestIgnoreEvent event)
            => testSomething(event);
    
    shared actual void testRunFinish(TestRunFinishEvent event)
            => write("1..``count-1``");
}