//! O `libc` com as constantes de rota que ele declara só no macOS (`net/route.h`).
//! No iOS o kernel é o mesmo XNU e o `sysctl` das rotas funciona; o libc 0.2.191
//! deixou de declarar por o cabeçalho não estar no SDK público. Os valores são os
//! do macOS.
#![allow(dead_code)]

pub use libc::*;

pub const RTF_UP: libc::c_int = 0x1;
pub const RTF_GATEWAY: libc::c_int = 0x2;
pub const RTF_HOST: libc::c_int = 0x4;
pub const RTF_IFSCOPE: libc::c_int = 0x1000000;

pub const RTM_VERSION: libc::c_int = 5;
pub const RTM_ADD: libc::c_int = 0x1;
pub const RTM_DELETE: libc::c_int = 0x2;
pub const RTM_CHANGE: libc::c_int = 0x3;
pub const RTM_GET: libc::c_int = 0x4;
pub const RTM_LOSING: libc::c_int = 0x5;
pub const RTM_REDIRECT: libc::c_int = 0x6;
pub const RTM_MISS: libc::c_int = 0x7;
pub const RTM_LOCK: libc::c_int = 0x8;
pub const RTM_RESOLVE: libc::c_int = 0xb;
pub const RTM_NEWADDR: libc::c_int = 0xc;
pub const RTM_DELADDR: libc::c_int = 0xd;
pub const RTM_IFINFO: libc::c_int = 0xe;
pub const RTM_NEWMADDR: libc::c_int = 0xf;
pub const RTM_DELMADDR: libc::c_int = 0x10;
pub const RTM_IFINFO2: libc::c_int = 0x12;
pub const RTM_NEWMADDR2: libc::c_int = 0x13;
pub const RTM_GET2: libc::c_int = 0x14;

pub const RTA_DST: libc::c_int = 0x1;
pub const RTA_GATEWAY: libc::c_int = 0x2;
pub const RTA_NETMASK: libc::c_int = 0x4;
pub const RTA_GENMASK: libc::c_int = 0x8;
pub const RTA_IFP: libc::c_int = 0x10;
pub const RTA_IFA: libc::c_int = 0x20;
pub const RTA_AUTHOR: libc::c_int = 0x40;
pub const RTA_BRD: libc::c_int = 0x80;

pub const RTAX_DST: libc::c_int = 0;
pub const RTAX_GATEWAY: libc::c_int = 1;
pub const RTAX_NETMASK: libc::c_int = 2;
pub const RTAX_GENMASK: libc::c_int = 3;
pub const RTAX_IFP: libc::c_int = 4;
pub const RTAX_IFA: libc::c_int = 5;
pub const RTAX_AUTHOR: libc::c_int = 6;
pub const RTAX_BRD: libc::c_int = 7;
pub const RTAX_MAX: libc::c_int = 8;
