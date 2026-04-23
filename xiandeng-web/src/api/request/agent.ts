import { Partition } from "@/models/account"
// import { $axiosBack } from "../client"
import { useAxiosRequest } from "@/composables/client"

async function upgradeAgent(targetType: string, currentUser?: boolean, accountId?: string) {
    const response = await useAxiosRequest({
        method: "post",
        url: "account/agent/upgrade",
        data: {
            target_type: targetType,
            account_id: accountId,
            current_user: currentUser
        }
    })
    return response.data
}
async function listMyAgents() {
    const response = await useAxiosRequest({
        method: "get",
        url: "account/my-agent/list"
    })
    return response.data
}

// async function listDirectAgents() {
//     const response = await useAxiosRequest({
//         method: "get",
//         url: "account/direct-agent/list"
//     })
//     return response.data
// }

async function listMyPartitionAgents(partition: string) {
    const response = await useAxiosRequest({
        method: "get",
        url: "account/my-partition/list",
        params: {
            partition
        }
    })
    return response.data
}

async function listSevenLevelAgents(partition: Partition, currentUser?: boolean, acctId?: string) {
    const response = await useAxiosRequest({
        method: "get",
        url: "account/agents/seven-level",
        params: {
            partition,
            current_user: currentUser,
            account_id: acctId ? acctId : undefined
        }
    })
    return response.data
}

async function listSubAgentDetails(subAccountId: string, currentUser?: boolean, currentAccountId?: string) {
    const response = await useAxiosRequest({
        method: "get",
        url: "account/sub-agent/details",
        params: {
            sub_agent_account_id: subAccountId,
            current_user: currentUser,
            current_account_id: currentAccountId
        }
    })
    return response.data
}

async function updateAgentPartition(accountId: string, partition: string) {
    const response = await useAxiosRequest({
        method: "post",
        url: "account/agent/partition",
        data: {
            account_id: accountId,
            partition
        }
    })
    return response.data
}

interface AgentAccount {
    accountname: string;
    createdat: string;
    id: string;
    pendingfee?: string;
    franchiseorderid?: string;
    status: string;
    type: string;
    targettype: string;
    upacctname: string;
    upstreamaccount: string;
}
async function searchAgents(accountNameLike: string) {
    const response = await useAxiosRequest({
        method: "get",
        url: "account/agents/search",
        params: {
            account_name_like: accountNameLike
        }
    })
    return response.data
}

// ... existing code ...

interface SearchAgentsWithAttributesRow {
    type: string | null;
    accountname?: string;
    createdat: string;
    status: string | null;
    partition: string | null;
    accountid: string | null;
    province?: string;
    city?: string;
    agentcode?: string;
    paymentmethodwechatoffline?: boolean;
    paymentmethodalipayoffline?: boolean;
    paymentmethodcardoffline?: boolean;
    paymentmethodwechatpay?: boolean;
    paymentmethodliuliupay?: boolean;
    couponinputenabled?: boolean;
    phone?: string;
    email?: string;
    orguri?: string;
    demo_flag?: boolean;
    demo_account?: string;
}

// ... existing code ...

interface QuerySearchAgentsWithAttributes {
    account_name_like?: string;
    phone_like?: string;
    email_like?: string;
}

async function searchAgentsWithAttributes(params: QuerySearchAgentsWithAttributes) {
    const response = await useAxiosRequest({
        method: "get",
        url: "account/agents/search/attributes",
        params
    })
    return response.data
}

interface PendingAgent {
    upagent: string;
    childagent: string;
    ordercreatedat: string;
}
async function pendingAgentsByFranchiseOrderId(franchiseOrderId: string) {
    const response = await useAxiosRequest({
        method: "get",
        url: "account/pending-agents/foid/" + franchiseOrderId,
    })
    return response.data
}

async function assignAgentAward(accountId: string) {
    const response = await useAxiosRequest({
        method: "post",
        url: "account/agent/assign_award/" + accountId,
    })
    return response.data
}

async function calcSumPv() {
    const response = await useAxiosRequest({
        method: "get",
        url: "account/partition/sum",
    })
    return response.data
}

async function updateAgentByHQ(account_id: string, partition?: string, accountname?: string, type?: string, status?: string, demo_flag?: boolean, demo_account?: string) {
    const response = await useAxiosRequest({
        method: "post",
        url: "account/hq/agent/update",
        data: {
            id: account_id,
            partition,
            accountname,
            type,
            status,
            demo_flag,
            demo_account
        }
    })
    return response.data
}

export {
    upgradeAgent,
    listMyAgents,
    // listDirectAgents,
    listMyPartitionAgents,
    listSevenLevelAgents,
    listSubAgentDetails,
    searchAgents,
    type PendingAgent,
    pendingAgentsByFranchiseOrderId,
    updateAgentPartition,
    updateAgentByHQ,
    type AgentAccount,

    assignAgentAward,
    calcSumPv,
    searchAgentsWithAttributes,
    type QuerySearchAgentsWithAttributes,
    type SearchAgentsWithAttributesRow,
}
