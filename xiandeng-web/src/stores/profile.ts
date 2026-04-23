import { defineStore } from 'pinia'
import { ref } from 'vue'
import {v4 as uuidv4} from 'uuid'
import {isUserGuardian, isUserStudent, type UserProfile, UserRoleType} from '@/models/user'
import { RoleData, getRoleOfUser } from '@/api/request/uam'
import { checkWindowSize } from '@/helpers/common'
import { WindowSize } from '@/helpers/constants'
import {OrgMetadata} from "@/models/org.ts";

export const useProfileStore = defineStore('profile', () => {

    const sessionId = ref(uuidv4())

    const userProfile = ref<UserProfile>({})

    const roleData = ref<RoleData>()

    async function updateRoleData() {
        await getRoleOfUser()
        .then((res) => {
            console.log(res.data)
            roleData.value = res.data
        })
    }

    function isGuardian() {
        return isUserGuardian(roleData.value?.usertype as UserRoleType)
    }

    function isStudent() {
        return isUserStudent(roleData.value?.usertype as UserRoleType)

    }

    function adjustWindowSize() {
        windowSize.value = checkWindowSize()

    }

    function setupWindowSizeCheck() {
        adjustWindowSize()
        window.addEventListener('resize', adjustWindowSize)
    }

    const windowSize = ref<WindowSize>()

    const orgMetadata = ref<OrgMetadata>()

    const userViewPrivilege = ref<string[]>([])

    function hasPrivilege(privilege: string) {
        return userViewPrivilege.value.includes(privilege)
    }

    function getItemByPrivilegeOrNull(privilege: string, item: any) {
        return hasPrivilege(privilege) ? item : null
    }


    return {
        sessionId,
        userProfile,

        roleData,
        updateRoleData,
        isGuardian,
        isStudent,

        setupWindowSizeCheck,
        windowSize,

        orgMetadata,
        userViewPrivilege,
        hasPrivilege,
        getItemByPrivilegeOrNull
    }
})
