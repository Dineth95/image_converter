package com.dsolutions.image_converter

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito

/*
 * JVM unit tests for the channel dispatch. The actual conversions use Android
 * framework PDF classes, so they are covered by the example app's
 * integration test (example/integration_test) on a device/emulator.
 *
 * Run with `./gradlew testDebugUnitTest` from `example/android/`.
 */
internal class ImageConverterPluginTest {
  @Test
  fun onMethodCall_unknownMethod_returnsNotImplemented() {
    val plugin = ImageConverterPlugin()
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

    plugin.onMethodCall(MethodCall("doesNotExist", null), mockResult)

    Mockito.verify(mockResult).notImplemented()
  }
}
