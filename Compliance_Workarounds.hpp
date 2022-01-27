#pragma once

// need to include something from the standard library so _LIBCPP_VERSION gets defined, so don't move
// these #includes under that conditional compile
#include <compare>
#include <chrono>           // hh_mm_ss<>
#include <cmath>            // abs()
#include <iostream>         // ostream
#include <string>
#include <type_traits>      // is_floating_point<>, decay<>, is_convertible_v<>
#include <utility>          // declval<>


// C++20 Transition Workarounds
//    _LIBCPP_VERSION is set if using LLVM's libc++ library
//    __GLIBCXX__     is set if using GNU's libstdc++ library (set to date of release)
//           (__GLIBC__ * 1'000 + __GLIBC_MINOR__)  gives libstdc++ version
//    __GNUC__        is defined if using GCC, but also sometimes when using Clang
//          (__GNUC__ * 1'000'000 + __GNUC_MINOR__ * 1'000 + __GNUC_PATCHLEVEL__) give gcc version



#if defined( _LIBCPP_VERSION )
  namespace std
  {
    #if _LIBCPP_VERSION < 14'000
       inline strong_ordering operator<=>( const string & lhs, const string & rhs) noexcept
       {
         int result = lhs.compare( rhs );
         return result == 0  ?  strong_ordering::equivalent
              : result  < 0  ?  strong_ordering::less
              :                 strong_ordering::greater;
       }
    #else
      #pragma message ("A potentially obsolete C++20 workaround is present.  Either remove the workaround if no longer needed, or update the version number requiring it")
    #endif


    #if _LIBCPP_VERSION < 14'000
       template<class T1, class T2>
       constexpr weak_ordering  compare_weak_order_fallback( T1 && lhs, T2 && rhs ) noexcept
       {
         bool is_equal;
         if constexpr( std::is_floating_point_v<std::decay_t<T1>>  &&  std::is_floating_point_v<decay_t<T2>> )   is_equal = std::abs( lhs - rhs ) < 1e-9;
         else                                                                                                    is_equal = lhs == rhs;

         return is_equal    ?  weak_ordering::equivalent
              : lhs  < rhs  ?  weak_ordering::less
              :                weak_ordering::greater;
       }
    #else
      #pragma message ("A potentially obsolete C++20 workaround is present.  Either remove the workaround if no longer needed, or update the version number requiring it")
    #endif


    #if _LIBCPP_VERSION < 13'000
      template<typename _From, typename _To>
      concept convertible_to = is_convertible_v<_From, _To> && requires
      {
        static_cast<_To>( declval<_From>() );
      };
    #elif _LIBCPP_VERSION > 13'000  // resolved in version 13, but we're running a mix of version 12 and 13 for a while
      #pragma message ("A potentially obsolete C++20 workaround is present.  Either remove the workaround if no longer needed, or update the version number requiring it")
    #endif
  } // namespace std
#endif // defined( _LIBCPP_VERSION )




#if( ( defined( _LIBCPP_VERSION ) && (_LIBCPP_VERSION                      <  14'000 )) || \
     ( defined( __GLIBCXX__     ) && ( __GLIBC__ * 1'000 + __GLIBC_MINOR__ <=  2'040 )) )     // roughly a little beyond gcc 11.2.1 (run "ldd --version" and "gcc --version" at the command line)
  namespace std::chrono                                                                       // Check lib version and not gcc version, clang may use gnu's libstdc++ library
  {
    template<class Duration>
    inline std::ostream & operator<<( std::ostream & os, const std::chrono::hh_mm_ss<Duration> & t )
    {
      return os << t.hours     ().count() << ':'
                << t.minutes   ().count() << ':'
                << t.seconds   ().count() << "."
                << t.subseconds().count();
    }
  }    // namespace std::chrono
#else
  #pragma message( "A potentially obsolete C++20 workaround is present.  Either remove the workaround if no longer needed, or update the version number requiring it" )
#endif    // ( _LIBCPP_VERSION || __GLIBCXX__ )
