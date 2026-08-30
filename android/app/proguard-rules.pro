# منع R8 من حذف فئات Markwon و Commonmark
-dontwarn org.commonmark.**
-keep class org.commonmark.** { *; }

-dontwarn io.noties.markwon.**
-keep class io.noties.markwon.** { *; }

# قواعد خاصة بمكتبة Kommunicate
-dontwarn io.kommunicate.**
-keep class io.kommunicate.** { *; }