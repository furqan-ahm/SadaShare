import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class WindowsTitleBar extends StatelessWidget {
  const WindowsTitleBar({Key? key, this.showMaximize = false})
      : super(key: key);

  final bool showMaximize;

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Row(
        children: [
          (Navigator.of(context).canPop())
              ? IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 12,
                  ))
              : const SizedBox.shrink(),
          Expanded(child: MoveWindow()),
          Row(
            children: [
              MinimizeWindowButton(
                colors: WindowButtonColors(iconNormal: Colors.white),
              ),
              (showMaximize)
                  ? MaximizeWindowButton(
                      colors: WindowButtonColors(iconNormal: Colors.white),
                    )
                  : const SizedBox.shrink(),
              CloseWindowButton(
                colors: WindowButtonColors(iconNormal: Colors.white),
              )
            ],
          )
        ],
      ),
    );
  }
}
