import { defineStore } from 'pinia'
import { ref } from 'vue'
import {RequireRoleType} from "@/models/user.ts";

export const usePermissionStore = defineStore('permission', () => {

    const requireRole = ref<RequireRoleType>()

    const setRequireRole = (role: RequireRoleType) => {
        requireRole.value = role
        console.log("setRequireRole to: ", role)
    }

    return {
        requireRole,
        setRequireRole
    }
})