```dart
Navigator.of(context).push(
            PerfectBottomSheetRoute(
              builder: (context, controller) {
                return Material(
                  color: Colors.transparent,
                  child: ListView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom,
                      top: 20,
                    ),
                    controller: controller,
                    children: List.generate(
                      30,
                      (index) => Text("$index"),
                    ),
                  ),
                );
              },
            ),
          );
```