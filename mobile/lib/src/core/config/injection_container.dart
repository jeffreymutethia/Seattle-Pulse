// import 'package:get_it/get_it.dart';
// import 'package:dio/dio.dart';
// import 'package:seattle_pulse_mobile/src/core/api/api_client.dart';
// import 'package:seattle_pulse_mobile/src/features/auth/data/implements/auth_repository_impl.dart';
// import 'package:seattle_pulse_mobile/src/features/auth/data/sources/auth_remote_data_source.dart';
// import 'package:seattle_pulse_mobile/src/features/auth/domain/repositories/repositories.dart';
// import 'package:seattle_pulse_mobile/src/features/auth/domain/usecases/verify_otp_usecase.dart';
// import 'package:seattle_pulse_mobile/src/features/auth/presentation/bloc/auth_bloc.dart';

// import '../../features/auth/domain/usecases/register_usecase.dart';

// final sl = GetIt.instance;

// void init() {
//   // 1. Core
//   sl.registerLazySingleton(() => Dio());
//   sl.registerLazySingleton(() => ApiClient(sl()));

//   // 2. Auth - Data Sources
//   sl.registerLazySingleton<AuthRemoteDataSource>(
//     () => AuthRemoteDataSourceImpl(sl()),
//   );

//   // 3. Auth - Repositories
//   // sl.registerLazySingleton<AuthRepository>(
//   //   () => AuthRepositoryImpl(sl()),
//   // );

//   // 4. Auth - Use Cases
//   sl.registerLazySingleton(() => RegisterUseCase(sl()));
//   sl.registerLazySingleton(() => VerifyOTPUseCase(sl()));

//   // 5. Auth - BLoC
//   sl.registerFactory(
//     () => AuthBloc(
//       registerUseCase: sl(),
//       verifyOTPUseCase: sl(),
//     ),
//   );
// }
