import 'dart:io';

import 'package:eros_n/common/const/const.dart';
import 'package:eros_n/common/global.dart';
import 'package:eros_n/network/request.dart';
import 'package:eros_n/pages/user/user_provider.dart';
import 'package:eros_n/routes/routes.dart';
import 'package:eros_n/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final FocusNode _usernameFocusNode;
  late final FocusNode _passwordFocusNode;
  late bool _obscurePassword;
  late bool _logining;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _usernameFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _obscurePassword = true;
    _logining = false;
  }

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
  }

  Future<void> _login() async {
    logger.d(
      'Username: ${_usernameController.text}, Password: ${_passwordController.text}',
    );

    if (_logining) {
      return;
    }

    setState(() {
      _logining = true;
    });

    try {
      await ref.read(userProvider.notifier).login(
            username: _usernameController.text.trim(),
            password: _passwordController.text.trim(),
          );
    } catch (e) {
      logger.e(e);
    } finally {
      setState(() {
        _logining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_circle_rounded,
                size: 100.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              TextField(
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  // hintText: 'Enter your username',
                ),
                onEditingComplete: () {
                  _usernameFocusNode.unfocus();
                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                },
              ),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                decoration: InputDecoration(
                  labelText: 'Password',
                  // hintText: 'Enter your password',
                  suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: _obscurePassword
                          ? const Icon(Icons.visibility)
                          : const Icon(Icons.visibility_off)),
                ),
                obscureText: _obscurePassword,
                onEditingComplete: () {
                  _passwordFocusNode.unfocus();
                  _login();
                },
              ),
              Container(
                padding: const EdgeInsets.only(top: 48.0),
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ),
                  onPressed: _logining
                      ? null
                      : () async {
                          await _login();
                        },
                  child: _logining
                      ? SizedBox(
                          height: 20.0,
                          width: 20.0,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Login'),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                      onPressed: () async {
                        final cookies = await erosRouter
                            .pushNamed<List<Cookie>>(NHRoutes.webLogin);
                        logger.d('==>> cookies: $cookies');
                        if (cookies != null) {
                          await Global.cookieJar
                              .delete(Uri.parse(NHConst.baseUrl));
                          await Global.cookieJar.saveFromResponse(
                              Uri.parse(NHConst.baseUrl), cookies);
                          await ref.read(userProvider.notifier).loginWithWeb();
                        }
                      },
                      child: const Text(
                        'Login by web',
                        style: TextStyle(decoration: TextDecoration.underline),
                      )),
                  TextButton(
                      onPressed: () {
                        erosRouter.push(NhWebViewRoute(
                          initialUrl: NHConst.registerUrl,
                          title: 'Register',
                        ));
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(decoration: TextDecoration.underline),
                      )),
                ],
              ),
              if (kDebugMode)
                TextButton(
                    onPressed: () async {
                      final u = await getInfoFromIndex(refresh: true);
                      logger.d('==>> u: $u');
                    },
                    child: const Text(
                      'Get info from Index',
                      style: TextStyle(decoration: TextDecoration.underline),
                    )),
              if (kDebugMode)
                TextButton(
                    onPressed: () async {
                      final userUrl = ref.read(userProvider).userUrl ?? '';
                      logger.d('==>> userUrl: $userUrl');
                      if (userUrl.isNotEmpty) {
                        final u = await getInfoFromUserPage(
                            url: userUrl, refresh: true);
                        logger.d('==>> u: $u');
                      }
                    },
                    child: const Text(
                      'Get info from user page',
                      style: TextStyle(decoration: TextDecoration.underline),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}