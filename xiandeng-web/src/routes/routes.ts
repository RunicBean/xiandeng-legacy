import { type RouteRecordRaw} from 'vue-router'
import {
  requireEntitlement,
} from './guards'
import {RequireRoleType} from "@/models/user.ts";
import _ from 'lodash';

const SignupVue = () => import('../components/Signup.vue')
const SignupFinish = () => import('@/components/inform/SignupFinish.vue')
const InviteAccountUser = () => import('@/components/InviteAccountUser.vue')
const CodeScan = () => import('@/components/CodeScan.vue')
// const AlipayOfflinePay = () => import('@/components/oa_page/payment/AlipayOfflinePay.vue')
// const WechatOfflinePay = () => import('@/components/oa_page/payment/WechatOfflinePay.vue')
// const InviteUserCode = () => import('@/components/oa_page/resource/InviteUserCode.vue')


// const RecruitMenu = () => import('@/components/oa_page/resource/RecruitMenu.vue')
// const QianliaoActivate = () => import('@/components/oa_page/payment/QianliaoActivate.vue')
// const SkuMenu = () => import('@/components/oa_page/payment/SkuMenu.vue')

// const StudentPlanningReport = () => import('@/components/oa_page/resource/StudentPlanningReport.vue')
// const SkuDetail = () => import('@/components/oa_page/payment/SkuDetail.vue')

// OA Page
const OaPageFooter = () => import('@/components/oa_page/segments/OaPageFooter.vue')
const OaPageHeader = () => import('@/components/oa_page/segments/OaPageHeader.vue')

// Admin Components
const AdminVue = () => import('../components/layouts/Admin.vue')
const ResourceMainVue = () => import('../components/admin/layouts/ResourceMain.vue')
const ResourceSidebarVue = () => import('../components/admin/layouts/ResourceSidebar.vue')
const SettingMainVue = () => import('../components/admin/layouts/SettingMain.vue')
const SettingSidebarVue = () => import('../components/admin/layouts/SettingSidebar.vue')
const AdminHome = () => import('@/components/admin/resource/AdminHome.vue')
const JobReference = () => import('@/components/admin/resource/JobReference.vue')
// const AgentConfig = () => import('@/components/admin/resource/AgentConfig.vue')
const StudentPlanningReportList = () => import('@components/admin/resource/products/StudentPlanningReportList.vue')
const MyStudentPlanningReportList = () => import('@components/admin/resource/products/MyStudentPlanningReportList.vue')
const StudentPlanningReportDetail = () => import('@/components/admin/resource/products/StudentPlanningReportDetail.vue')
const Coupon = () => import('@/components/admin/resource/Coupon.vue')
const Student = () => import('@/components/admin/resource/Student.vue')
const MyStudent = () => import('@/components/admin/resource/MyStudent.vue')
const MyAgent = () => import('@/components/admin/resource/MyAgent.vue')
const HeadQuarterAuthorize = () => import('@/components/admin/hqpanel/HeadQuarterAuthorize.vue')
const HQAuthAgent = () => import('@/components/admin/hqpanel/authorize/HQAuthAgent.vue')
const HQAuthStudent = () => import('@/components/admin/hqpanel/authorize/HQAuthStudent.vue')
const UserVue = () => import('../components/admin/setting/UserSetting.vue')
const Invitation = () => import('@/components/admin/resource/Invitation.vue')

const PortalVue = () => import('../components/layouts/Portal.vue')
// const AutoClose = () => import('@/components/AutoClose.vue')
const Login = () => import('../components/Login.vue')
const Idp = () => import('../components/Idp.vue')
const Forwarder = () => import('../components/Forwarder.vue')

const StudentOnboarding = () => import('@/components/StudentOnboarding.vue')
const Construction = () => import('@/components/Construction.vue')
const NotFound = () => import('@/components/NotFound.vue')

export const routes: RouteRecordRaw[] = [
    {
      path: '/showcase/:companyPath',
      component: () => import('@/components/showcase/LayoutOne.vue'),
    },
    // {
    //   path:'/autoclose',
    //   component: AutoClose
    // },
    {
      path:'/signup/:refcode',
      name: 'signup',
      component: SignupVue
    },
    {
      path:'/signup/continue/:next',
      name: 'signup-continue',
      component: SignupFinish
    },
    {
      // 有两个参数必须：?account_id=xxx&invite_role=xxx
      path: '/invite',
      name: 'invite-to-account',
      component: InviteAccountUser
    },
    {
      name: 'code-scan',
      path: '/codescan',
      component: CodeScan
    },
    {
      path: '/',
      component: PortalVue,
      children: [
        {
          name: 'login',
          path: 'login',
          component: Login,
          meta: {
            requireRole: RequireRoleType.AGENT
          }
        },
        {
          name: 'idp',
          path: 'idp',
          component: Idp,
          meta: {
            requireRole: RequireRoleType.AGENT
          }
        },
        {
          name: 'forwarder',
          path: 'forwarder',
          component: Forwarder,
          meta: {
            requireRole: RequireRoleType.AGENT
          }
        },
        {
          name: 'construction',
          path: '',
          component: Construction
        },
        // {
        //   name: 'portal_student-onboarding',
        //   path: 'onboarding',
        //   component: StudentOnboarding
        // },
        {
          name: 'result',
          path: 'result/:type',
          component: () => import("@components/Result.vue")
        },
        {
          name: 'signup-required',
          path: 'signup-required',
          component: () => import('@components/SignupRequired.vue')
        },
        {
          name: 'terms-overall',
          path: 'terms/overall',
          component: () => import('@components/TermsOverall.vue')
        }
      ]
    },
    {
      name: 'oa-noauth',
      path: '/oa-noauth',
      component: () => import('@components/layouts/OaPage.vue'),
      children: [
        {
          name: 'noauth-prod-menu',
          path: 'prodmenu',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/payment/SkuMenuNoSignin.vue')
          }
        },
        {
          name: 'noauth-prod-detail',
          path: 'proddetail/:productid',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/payment/SkuDetailNoSignin.vue')
          }
        },
        {
          name: 'noauth-notice',
          path: 'notice',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/payment/NoSigninNotice.vue')
          }
        },

        {
          name: 'agent-checkout',
          path: 'agent-checkout',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/payment/AgentCheckout.vue')
          }
        }

      ]
    },
    {
      name: 'oa-agent',
      path: '/oa',
      component: () => import('@components/layouts/OaPage.vue'),
      children: [
        {
          name: 'forget-password-agent',
          path: 'forget-password-agent',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/resource/ForgetPassword.vue')
          }
        }
      ],
      meta: {
        requireRole: RequireRoleType.AGENT,
        requireAuth: true
      }
    },
    {
      name: 'oa-useronly',
      path: '/oa',
      component: () => import('@components/layouts/OaPage.vue'),
      children: [
        {
          name: 'forget-password',
          path: 'forget-password',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/resource/ForgetPassword.vue')
          }
        }
      ],
    },
    {
      name: 'oa',
      path: '/oa',
      component: () => import('@components/layouts/OaPage.vue'),
      children: [
        {
          name: 'prod-detail',
          path: 'proddetail/:productid',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@/components/oa_page/payment/SkuDetail.vue')
          },
          meta: {
            updateRoleData: true
          }
        },
        // {
        //   name: 'payment-wechat-offline-qrcode',
        //   path: 'payment/wechat-offline',
        //   components: {
        //     oa_footer: OaPageFooter,
        //     oa_header: OaPageHeader,
        //     default: WechatOfflinePay
        //   }
        // },
        // {
        //   name: 'payment-alipay-offline-qrcode',
        //   path: 'payment/alipay-offline',
        //   components: {
        //     oa_footer: OaPageFooter,
        //     oa_header: OaPageHeader,
        //     default: AlipayOfflinePay
        //   }
        // },
        {
          // 家长邀请学生路由
          name: 'invite-user-code',
          path: 'invite-user-code',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/resource/InviteUserCode.vue')
          }
        },
        {
          name: 'prod-menu',
          path: 'prodmenu',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/payment/SkuMenu.vue')
          },
          meta: {
            demoForbidden: true
          }
        },
        {
          name: 'activate-qianliao',
          path: 'q-activate',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/payment/QianliaoActivate.vue')
          },
          meta: {
            blockGuardianUser: true,
            demoForbidden: true
          }
        },
        {
          name: 'recruit-menu',
          path: 'recruit',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/resource/RecruitMenu.vue')
          },
          beforeEnter: requireEntitlement("招聘信息")
        },
        {
          name: 'job-reference',
          path: 'job-reference',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/common_components/JobReference.vue')
          },
          beforeEnter: requireEntitlement("考研就业参考")
        },
        {
          name: 'student-onboarding',
          path: 'onboarding',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: StudentOnboarding
          }
        },
        {
          name: 'student',
          path: 'planning',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@components/oa_page/resource/StudentPlanningReport.vue')
          },
          beforeEnter: requireEntitlement("规划报告"),
          meta: {
            updateRoleData: true
          }
        },
        {
          path: 'join-agent',
          name: 'join-agent',
          components: {
            oa_footer: OaPageFooter,
            oa_header: OaPageHeader,
            default: () => import('@/components/JoinAgent.vue')
          }
        },

      ],
      meta: {
        requireRole: RequireRoleType.STUDENT,
        requireAuth: true
      }
    },
    // {
    //   name: 'oa-test',
    //   path: '/oa_test',
    //   component: () => import('@components/layouts/OaPage.vue'),
    //   children: [
    //     {
    //       name: 'student',
    //       path: 'student/planning',
    //       components: {
    //         oa_footer: OaPageFooter,
    //         oa_header: OaPageHeader,
    //         default: StudentPlanningReport
    //       }
    //     }
    //   ]
    // },
    {
      name: 'adm',
      path: '/admin',
      component: AdminVue,
      children: [
        {
          name: 'adm-home',
          path: 'resource/home',
          components: {
            Main: AdminHome,
            SideBar: ResourceSidebarVue
          }
        },
        {
          name: 'adm-resource',
          path: 'resource',
          components: {
            Main: ResourceMainVue,
            SideBar: ResourceSidebarVue
          },
          children: [
            {
              name: 'adm-resource-invitation',
              path: 'invitation',
              component: Invitation
            },
            {
              name: 'adm-resource-student',
              path: 'student',
              component: Student
            },
            {
              name: 'adm-resource-my-student',
              path: 'my-student',
              component: MyStudent
            },
            {
              name: 'adm-resource-planning_report',
              path: 'planning-report',
              component: StudentPlanningReportList
            },
            {
              name: 'adm-resource-my-planning_report',
              path: 'my-planning-report',
              component: MyStudentPlanningReportList
            },

            {
              name: 'adm-resource-coupon',
              path: 'coupon',
              component: Coupon
            },
            {
              name: 'adm-resource-delivery',
              path: 'delivery',
              component: () => import('@/components/admin/resource/Delivery.vue')
            },

            {
              name: 'adm-resource-dependent-sales-orders',
              path: 'orders',
              component: () => import('@/components/admin/resource/dependent_sales/Orders.vue')
            },
            {
              name: 'adm-resource-dependent-sales-myorders',
              path: 'myorders',
              component: () => import('@/components/admin/resource/dependent_sales/MyOrders.vue')
            },
            {
              name: 'adm-resource-inventory',
              path: 'inventory',
              component: () => import('@/components/admin/resource/InventoryOrder.vue')
            },


            // {
            //   name: 'adm-agent-config',
            //   path: 'a-config',
            //   component: AgentConfig
            // },
            {
              name: 'adm-resource-profile',
              path: 'profile',
              component: () => import('@/components/admin/resource/Profile.vue'),
              children: [
                {
                  name: 'adm-resource-profile-withdrawmethod',
                  path: 'withdrawmethod',
                  component: () => import('@/components/admin/resource/profile/WithdrawMethod.vue')
                },
              ]
            },
            {
              name: 'adm-resource-wallet',
              path: 'wallet',
              component: () => import('@/components/admin/resource/Wallet.vue'),
              children: [
                {
                  name: 'adm-resource-wallet-activity',
                  path: 'activity',
                  components: {
                    Main: () => import('@/components/admin/resource/wallet/BalanceActivity.vue')
                  }
                },
                {
                  name: 'adm-resource-wallet-balance',
                  path: 'balance',
                  components: {
                    Main: () => import('@/components/admin/resource/wallet/BalanceStat.vue')
                  }
                }
              ]
            },

            {
              name: 'adm-resource-jobreference',
              path: 'jobreference',
              component: JobReference
            },
            {
              name: 'adm-myagents',
              path: 'agents',
              component: MyAgent
            }
          ]
        },
        {
          name: 'adm-hqpanel',
          path: 'hqpanel',
          components: {
            Main: () => import('@/components/admin/layouts/HqpanelMain.vue'),
            SideBar: () => import('@/components/admin/layouts/HqpanelSidebar.vue')
          },
          children: [
            {
              name: 'adm-hqpanel-authorize',
              path: 'authorize',
              component: HeadQuarterAuthorize,
              children: [
                {
                  name: 'adm-hqpanel-authorize-student',
                  path: 'student',
                  component: HQAuthStudent
                },
                {
                  name: 'adm-hqpanel-authorize-agent',
                  path: 'agent',
                  component: HQAuthAgent
                }
              ]
            },
            {
              name: 'adm-hqpanel-agent-editor',
              path: 'agent-editor',
              component: () => import('@/components/admin/hqpanel/AgentEditor.vue')
            },
            {
              name: 'adm-hqpanel-inventory-approval',
              path: 'inventory-approval',
              component: () => import('@/components/admin/hqpanel/InventoryApproval.vue')
            },
            {
              name: 'adm-hqpanel-adjustment',
              path: 'adjustment',
              component: () => import('@/components/admin/hqpanel/Adjustment.vue')
            }
          ]
        },
        {
          name: 'adm-setting',
          path: 'setting',
          components: {
            Main: SettingMainVue,
            SideBar: SettingSidebarVue
          },
          children: [
            {
              name: 'adm-setting-user',
              path: 'user',
              component: UserVue
            }
          ]
        }
      ],
      meta: {
        requireRole: RequireRoleType.AGENT,
        requireAuth: true,
        requireAgentCheck: true,
        updateRoleData: true,
        requireEntityMap: true,
        blockStudentRole: true
      },
      beforeEnter: (to) => {
        if (to.name == 'adm' || to.name == 'adm-resource') {
          return {name: "adm-home"}
        } else if (to.name == 'org-adm' || to.name == 'org-adm-resource') {
          return {name: "org-adm-home"}
        } else {
          return true
        }
      }
    },
  {
    name: 'student_planning_report_detail',
    path: '/planning-report-detail/:account_id',
    component: StudentPlanningReportDetail,
    meta: {
      requireAuth: true,
      requireRole: RequireRoleType.AGENT
    }
  },
    // {
    //   path: '/login',
    //   component: Login
    // },
    {
      name: 'not-found',
      path: '/:path(.*)',
      component: NotFound
    }
  ]

// 递归函数，用于修改每层的 name
function renameRoutes(routes: RouteRecordRaw[]): RouteRecordRaw[] {
  return routes.map(route => {
    // 修改当前层的 name
    const modifiedRoute: RouteRecordRaw = {
      ...route,
      name: route.name ? `org-${route.name as string}` : undefined,
        path: route.path.replace(/^\//, '')
    };

    // 如果存在 children，递归处理
    if (route.children && route.children.length > 0) {
      modifiedRoute.children = renameRoutes(route.children);
    }

    return modifiedRoute;
  });
}

export const orgRoutes: RouteRecordRaw[] = [
  {
    path: '/org/:org_name',
    component: () => import('@/components/OrgView.vue'),
    children: renameRoutes(routes)
  }
]
