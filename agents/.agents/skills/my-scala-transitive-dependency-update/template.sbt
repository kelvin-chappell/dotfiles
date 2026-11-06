/*
 * To test whether any of these entries are redundant:
 * 1. Comment it out
 * 2. Run `sbt Runtime/dependencyList`
 * 3. If no earlier version appears in the dependency list, the entry can be removed.
 */
val safeTransitiveDependencies = Seq(
  // add patched transitive dependencies here...
)

libraryDependencies ++= ... 
  safeTransitiveDependencies,
