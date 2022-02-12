import 'package:bloc_test/bloc_test.dart';
import 'package:my_app/domain/entities/account_entity.dart';
import 'package:my_app/main/routes/app_routes.dart';
import 'package:my_app/ui/helpers/user_manager.dart';
import 'package:my_app/ui/pages/feed/cubit/feed_cubit.dart';
import 'package:my_app/ui/pages/feed/cubit/feed_state.dart';
import 'package:my_app/ui/pages/feed/feed_page.dart';
import 'package:my_app/ui/pages/feed/post_viewmodel.dart';
import 'package:my_app/ui/pages/welcome/welcome_page.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

class FeedCubitSpy extends MockBloc<FeedState> implements FeedCubit {}

class NavigatorObserverSpy extends Mock implements NavigatorObserver {}

main() {
  FeedCubitSpy cubit;
  NavigatorObserver navigatorObserver;
  String user;
  String email;
  String message;
  final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();

  setUp(() {
    cubit = FeedCubitSpy();
    user = faker.person.name();
    email = faker.internet.email();
    navigatorObserver = NavigatorObserverSpy();
    message = faker.lorem.sentence();
  });

  Future _loadPage(WidgetTester tester) async {
    final Map<String, WidgetBuilder> routes = {
      AppRoutes.feed: (_) => FeedPage(),
      AppRoutes.welcome: (_) => WelcomePage(),
    };

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserManager()
          ..addUser(
            AccountEntity(token: '', id: 1, username: user, email: email),
          ),
        child: MultiBlocProvider(
          providers: [BlocProvider<FeedCubit>.value(value: cubit)],
          child: MaterialApp(
            navigatorKey: navigator,
            initialRoute: AppRoutes.feed,
            routes: routes,
            navigatorObservers: [navigatorObserver],
          ),
        ),
      ),
    );
  }

  testWidgets('Should show loading when states is FeedLoading',
      (WidgetTester tester) async {
    when(cubit.state).thenAnswer((_) => FeedLoading());

    await _loadPage(tester);

    final loading = find.byType(CircularProgressIndicator);
    expect(loading, findsOneWidget);
  });

  testWidgets('Should show empty list when state is FeedLoaded with no posts',
      (WidgetTester tester) async {
    when(cubit.state).thenAnswer((_) => FeedLoaded(news: []));

    await _loadPage(tester);

    final listView = find.byType(ListView);
    expect(listView, findsOneWidget);
    expect(
        (listView.evaluate().first.widget as ListView).semanticChildCount, 0);
  });

  testWidgets('Should show list when state is FeedLoaded with posts',
      (WidgetTester tester) async {
    when(cubit.state)
        .thenAnswer((_) => FeedLoaded(news: _newsMock(message, user)));

    await _loadPage(tester);

    final listView = find.byType(ListView);
    expect(listView, findsOneWidget);
    expect(
        (listView.evaluate().first.widget as ListView).semanticChildCount, 2);
    expect(find.text(message), findsOneWidget);
    expect(find.text(user), findsOneWidget);
  });

  testWidgets('Should show ReloadScreen widget when states is FeedError',
      (WidgetTester tester) async {
    when(cubit.state).thenAnswer((_) => FeedError('error'));

    await _loadPage(tester);

    expect(find.text('error'), findsOneWidget);
    expect(find.text('ለመሙላት'), findsOneWidget);
  });

  testWidgets('Should call loadPosts on reload click',
      (WidgetTester tester) async {
    when(cubit.state).thenAnswer((_) => FeedError('error'));

    await _loadPage(tester);
    await tester.tap(find.text('ለመሙላት'));
    verify(cubit.load()).called(2);
  });

  testWidgets('Should show Drawer when tap in menu icon',
      (WidgetTester tester) async {
    await _loadPage(tester);

    final menuIcon = find.byIcon(Icons.menu);
    expect(menuIcon, findsOneWidget);

    await tester.tap(menuIcon);
    await tester.pump();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text(user), findsOneWidget);
    expect(find.text(email), findsOneWidget);
  });

  testWidgets('Should call logoutUser when tap in ለመውጣት',
      (WidgetTester tester) async {
    when(cubit.state).thenReturn(FeedInitial());

    await _loadPage(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();

    final exit = find.text('ለመውጣት');
    expect(exit, findsOneWidget);
  });

  testWidgets('Should navigate to WelcomePage if state is LogoutUser',
      (WidgetTester tester) async {
    when(cubit.state).thenReturn(FeedInitial());

    whenListen<FeedState>(
      cubit,
      Stream.fromIterable(
        [
          LogoutUser(),
        ],
      ),
    );

    await _loadPage(tester);
    await tester.pumpAndSettle();

    verify(navigatorObserver.didPush(any, any));
    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets('Should call loadPosts if fling RefreshIndicator',
      (WidgetTester tester) async {
    when(cubit.state)
        .thenAnswer((_) => FeedLoaded(news: _newsMock(message, user)));

    when(cubit.load()).thenAnswer((_) async => Future.delayed(Duration.zero));

    await _loadPage(tester);

    await tester.fling(find.text(message), const Offset(0.0, 300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    verify(cubit.load());
  });

  group('Create post', () {
    testWidgets(
        'Should show Alert when tap in floating button and call handleSavePost if has message',
        (WidgetTester tester) async {
      await _loadPage(tester);

      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(find.byType(AlertDialog), findsOneWidget);

      navigator.currentState.pop(message);
      await tester.pump();

      verify(cubit.handleSavePost(message: message));
    });

    testWidgets(
        'Should show Alert when tap in floating button and never call handleSavePost if not has message',
        (WidgetTester tester) async {
      await _loadPage(tester);

      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      navigator.currentState.pop();
      await tester.pump();

      verifyNever(cubit.handleSavePost(message: message));
    });
  });
  group('Edit post', () {
    testWidgets(
        'Should show BottomSheet when tap in more_vert icon button and call handleSavePost if has message',
        (WidgetTester tester) async {
      when(cubit.state)
          .thenAnswer((_) => FeedLoaded(news: _newsMock(message, user)));

      await _loadPage(tester);

      expect(find.byType(AlertDialog), findsNothing);

      final iconMoreVert = find.byIcon(Icons.more_vert);

      expect(iconMoreVert, findsOneWidget);

      await tester.tap(iconMoreVert);
      await tester.pumpAndSettle();

      final editButton = find.text('አርትዕ');

      expect(editButton, findsOneWidget);
      expect(find.text('አስወጋጅ'), findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      navigator.currentState.pop(message);
      await tester.pumpAndSettle();

      verify(cubit.handleSavePost(message: message, postId: 1));
    });

    testWidgets(
        'Should show BottomSheet when tap in more_vert icon button and never call handleSavePost if has not message',
        (WidgetTester tester) async {
      when(cubit.state)
          .thenAnswer((_) => FeedLoaded(news: _newsMock(message, user)));

      await _loadPage(tester);

      expect(find.byType(AlertDialog), findsNothing);

      final iconMoreVert = find.byIcon(Icons.more_vert);

      expect(iconMoreVert, findsOneWidget);

      await tester.tap(iconMoreVert);
      await tester.pumpAndSettle();

      final editButton = find.text('አርትዕ');

      expect(editButton, findsOneWidget);
      expect(find.text('አስወጋጅ'), findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      navigator.currentState.pop();
      await tester.pumpAndSettle();

      verifyNever(cubit.handleSavePost(message: message, postId: 1));
    });
  });

  group('Remove post', () {
    testWidgets(
        'Should show BottomSheet when tap in more_vert icon button and call handleRemovePost',
        (WidgetTester tester) async {
      when(cubit.state)
          .thenAnswer((_) => FeedLoaded(news: _newsMock(message, user)));

      await _loadPage(tester);

      expect(find.byType(AlertDialog), findsNothing);

      final iconMoreVert = find.byIcon(Icons.more_vert);

      expect(iconMoreVert, findsOneWidget);

      await tester.tap(iconMoreVert);
      await tester.pumpAndSettle();

      final removeButton = find.text('አስወጋጅ');
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      navigator.currentState.pop(1);
      await tester.pumpAndSettle();

      verify(cubit.handleRemovePost(postId: 1));
    });

    testWidgets(
        'Should show BottomSheet when tap in more_vert icon button and never call handleRemovePost',
        (WidgetTester tester) async {
      when(cubit.state)
          .thenAnswer((_) => FeedLoaded(news: _newsMock(message, user)));

      await _loadPage(tester);

      expect(find.byType(AlertDialog), findsNothing);

      final iconMoreVert = find.byIcon(Icons.more_vert);

      expect(iconMoreVert, findsOneWidget);

      await tester.tap(iconMoreVert);
      await tester.pumpAndSettle();

      final removeButton = find.text('አስወጋጅ');
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      navigator.currentState.pop();
      await tester.pumpAndSettle();

      verifyNever(cubit.handleRemovePost(postId: 1));
    });
  });
}

List<NewsViewModel> _newsMock(String message, String user) {
  return [
    NewsViewModel(
      message: message,
      date: 'January, 20 2020',
      user: user,
      userId: 1,
      id: 1,
    ),
    NewsViewModel(
      message: faker.lorem.sentence(),
      date: 'January, 20 2010',
      user: faker.person.name(),
      userId: 2,
      id: 2,
    )
  ];
}
