import {authorize, authorizeForStudent, checkEntitlement} from '@/api/request/uam';
import { useProfileStore } from '@/stores/profile';
import {type RouteLocationNormalized, RouteLocationRaw, RouteLocationNamedRaw} from 'vue-router'
import dayjs from 'dayjs'
import { useResourceStore } from '@/stores/resource';
import { AccountType } from '@/models/account';
import {usePermissionStore} from "@/stores/permission.ts";
import {isUserGuardian, RequireRoleType, UserRoleType} from "@/models/user.ts";
import {appendOrgPrefixUrl} from "@/helpers/common.ts";
import {AxiosResponse} from "axios";
// import {dayjs} from "element-plus";

export async function requireRole(to: RouteLocationNormalized) {
    if (to.meta.requireRole) {
        const permitStore = usePermissionStore()
        permitStore.setRequireRole(to.meta.requireRole as RequireRoleType)
    }
    return true
}

export async function requireAuth(to: RouteLocationNormalized, _: any) {
    const profileStore = useProfileStore()
    let next: RouteLocationNamedRaw | boolean = true;
    const thenFunc = (res: AxiosResponse) => {
        console.log(res);

        profileStore.userProfile.id = res.data.id;
        profileStore.userProfile.nickName = res.data.nick_name;
        profileStore.userProfile.aliasName = res.data.alias_name;
        profileStore.userProfile.avatarUrl = res.data.avatar_url;
        profileStore.userProfile.accountId = res.data.account_id;
        profileStore.userProfile.accountName = res.data.account_name;
        profileStore.userProfile.phone = res.data.phone;
        profileStore.userProfile.demoMode = res.data.demo_mode;
        if (res.data.agent_check) {
            profileStore.userProfile.agentCheck = res.data.agent_check;
        }
        console.log(to.meta);
        
        if (to.meta.demoForbidden) {
            if (res.data.demo_mode) {
                next = {
                    name: profileStore.orgMetadata?.uri ? 'org-result' : 'result',
                    params: {
                        type: 'demo_forbidden',
                        org_name: profileStore.orgMetadata?.uri
                    },
                }
                return
            }
        }
        // TODO: 接收authorize里面的agent check信息，然后传给agentcheck用的路由
        next = true
    }
    if (to.meta.requireAuth) {
        if (to.meta.requireRole == RequireRoleType.STUDENT) {
            await authorizeForStudent()
                .then(thenFunc)
                .catch((err) => {
                    console.log(err.response.data.message);
                    console.log(to.params.org_name)
                    const name = "login"
                    let login: RouteLocationRaw = {
                        name,
                        query: {
                            next: to.name?.toString()
                        }
                    }

                    next = login

                    if (err.response.data.errorCode == 100009) {
                        next = {
                            name: profileStore.orgMetadata?.uri ? 'org-result' : 'result',
                            params: {
                                type: 'custom_warning',
                                org_name: profileStore.orgMetadata?.uri
                            },
                            query: {
                                msg: '您没有权限访问此页面'
                            }
                        }
                    }

                })
        } else {
            await authorize(to.params.org_name as string)
                .then(thenFunc)
                .catch((err) => {
                    console.log(err.response.data.message);
                    console.log(to.params.org_name)
                    const name = to.params.org_name ? "org-login" : "login"
                    console.log(name)
                    let login: RouteLocationRaw = {
                        name,
                        params: {
                            org_name: to.params.org_name
                        },
                        query: {
                            next: to.name?.toString()
                        }
                    }

                    next = login

                    if (err.response.data.errorCode == 100009) {
                        next = {
                            name: profileStore.orgMetadata?.uri ? 'org-result' : 'result',
                            params: {
                                type: 'custom_warning',
                                org_name: profileStore.orgMetadata?.uri
                            },
                            query: {
                                msg: '您没有权限访问此页面'
                            }
                        }
                    }

                })
        }

        return next
    }
    return next

}

export async function requireAgentCheck(to: RouteLocationNormalized, _: any) {
    if (to.meta.requireAgentCheck) {
        const profileStore = useProfileStore()
        if (profileStore.userProfile.agentCheck) {
            switch (profileStore.userProfile.agentCheck.number) {
                case 100301:
                    const acExp = localStorage.getItem('agent-check-expires-at')
                    console.log(dayjs().unix())
                    console.log(Number(acExp))
                    if (acExp == null || dayjs().unix() > Number(acExp)) {
                        // 设置不出现agent check界面的时间
                        localStorage.setItem('agent-check-expires-at', String(dayjs().add(3, 'day').unix()));
                        return {
                            name: profileStore.orgMetadata?.uri ? 'org-agent-checkout' : 'agent-checkout',
                            query: {
                                account_id: profileStore.userProfile.accountId,
                                next: to.path
                            },
                            params: {
                                org_name: profileStore.orgMetadata?.uri
                            }
                        }
                    } else {
                        return true
                    }
                case 100302:
                    return {
                        path: appendOrgPrefixUrl("/oa-noauth/agent-checkout", profileStore.orgMetadata?.uri),
                        query: {
                        account_id: profileStore.userProfile.accountId,
                    }}
                case 100303:
                    return {
                        path: appendOrgPrefixUrl('/result/agent_not_upstream_partition', profileStore.orgMetadata?.uri)
                    }
                case 100304:
                    return {path: appendOrgPrefixUrl('/result/agent_closed', profileStore.orgMetadata?.uri)}
            }

        }
    }
}

export function requireEntitlement(entitlementString: string) {
    return async function(_: RouteLocationNormalized) {
        let next: boolean|object = false
        const profileStore = useProfileStore()
        await checkEntitlement(entitlementString)
        .then((res) => {
            console.log("entitlement => ", res.data.exists);

            next = res.data.exists
        })
        if (!next) {
            next = {path: appendOrgPrefixUrl('/result/not_in_service', profileStore.orgMetadata?.uri)}
        }
        return next
    }

}

export async function requireRoleData(to: RouteLocationNormalized) {
    const profileStore = useProfileStore()
    if (to.meta.updateRoleData) {
        await profileStore.updateRoleData()
        console.log("roleDataUpdate => ", "done");
    }
    // 防止 student 角色进入admin 页面
    if (to.meta.blockStudentRole) {
        if (profileStore.roleData?.accounttype == AccountType.STUDENT) {
            return {name: profileStore.orgMetadata?.uri ? 'org-result' : 'result', params: {type: 'custom_warning', org_name: profileStore.orgMetadata?.uri}, query: {msg: '您没有权限访问此页面'}}
        }
    }
    if (to.meta.blockGuardianUser) {
        if (isUserGuardian(profileStore.roleData?.usertype as UserRoleType)) {
            return {name: profileStore.orgMetadata?.uri ? 'org-result' : 'result', params: {type: 'custom_warning', org_name: profileStore.orgMetadata?.uri}, query: {msg: '家长不可以激活会员。请让学生自行激活'}}
        }
    }
    return true
}

export function setupWindowSizeEvent() {
    console.log("setup windowsize event");

    const profileStore = useProfileStore()
    profileStore.setupWindowSizeCheck()
    return true
}

export async function requireEntityMap(to: RouteLocationNormalized, _: any) {
    const resourceStore = useResourceStore()
    if (to.meta.requireEntityMap) {
        await resourceStore.updateEntityTypeWordingMap()
    }
}

