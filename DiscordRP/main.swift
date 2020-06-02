//
//  main.swift
//  DiscordRP
//
//  Created by Emil Pedersen on 22/05/2020.
//  Copyright © 2020 Orbisec. All rights reserved.
//

import Foundation
import SwordRPC
#if os(macOS)
import Cocoa
#endif

enum JoinReplyComplex: String {
    case alwaysYes, yesOnce
    case alwaysNo, noOnce
    case ask
    
    var simplified: JoinReply? {
        switch self {
        case .alwaysYes, .yesOnce:
            return .yes
        case .alwaysNo, .noOnce:
            return .no
        case .ask:
            return nil
        }
    }
    
    var shouldReset: Bool {
        switch self {
        case .alwaysYes, .alwaysNo, .ask:
            return false
        case .yesOnce, .noOnce:
            return true
        }
    }
}

var joinReply: JoinReplyComplex = .ask

var presence = RichPresence()
presence.details = "Bored"
presence.state = "In my room"
//presence.timestamps.start = Date().addingTimeInterval(6 * 3600)

presence.assets.largeImage = "cross"
presence.assets.largeText = "Nothing really"
//  presence.assets.smallImage = "character1"
//  presence.assets.smallText = "Character 1"
presence.party.max = 69
presence.party.size = 1
presence.party.id = "a-party"
//  presence.secrets.match = "matchSecret"
presence.secrets.join = "a-party-join"

func buildRPC() -> SwordRPC {
    /// Additional arguments:
    /// handlerInterval: Int = 1000 (decides how fast to check discord for updates, 1000ms = 1s)
    /// autoRegister: Bool = true (automatically registers your application to discord's url scheme (discord-appid://))
    /// steamId: String? = nil (this is for steam games on these platforms)
    let rpc = SwordRPC(appId: "713414089703162017")
    rpc.onConnect { rpc in
        print("connected")
        rpc.setPresence(presence)
    }

    rpc.onDisconnect { rpc, code, msg in
        print("\u{001B}[0;31mIt appears we have disconnected from Discord\u{001B}[0;0m")
    }

    rpc.onError { rpc, code, msg in
        print("\u{001B}[0;31mErr \(code): \(msg)\u{001B}[0;0m")
    }

    rpc.onJoinGame { rpc, secret in
        presence.party.id = String(secret.dropLast(5))
        presence.secrets.join = secret
        print("\u{001B}[0;35mJoining party \(presence.party.id!)\u{001B}[0;0m")
        rpc.setPresence(presence)
        print("\u{001B}[0;34mNote: Update manually the party count\u{001B}[0;0m")
    }

    rpc.onSpectateGame { rpc, secret in
        print("\u{001B}[0;35mOur user wants to spectate! [UNSUPPORTED]\u{001B}[0;0m")
    }

    rpc.onJoinRequest { rpc, request, secret in
        print("\u{001B}[0;35m\(request.username)#\(request.discriminator) wants to play with us!\u{001B}[0;0m")
        if let reply = joinReply.simplified {
            print("\u{001B}[0;35mReplied automatically with \(reply == .yes ? "YES" : "NO")\u{001B}[0;0m")
            rpc.reply(to: request, with: reply)
        } else {
            print("\u{001B}[0;34mUse \u{001B}[0;34mreply [alwaysYes / yesOnce / alwaysIgnore / ignoreOnce / alwaysNo / noOnce]\u{001B}[0;0m to reply to this request !\u{001B}[0;0m")
            #if os(macOS)
            NSSound.beep()
            #endif
            while true {
                sleep(1000)
                if let reply = joinReply.simplified {
                    rpc.reply(to: request, with: reply)
                    print("\u{001B}[0;35mSucessfully replied to this request with \(reply == .yes ? "YES" : "NO")\u{001B}[0;0m")
                    break
                }
            }
        }
        if joinReply.shouldReset {
            joinReply = .ask
        }
    }
    return rpc
}

var rpc = buildRPC()

print("connecting")
rpc.connect()

func timeSeconds(_ string: String) -> Double {
    if string.hasSuffix("m") {
        return (Double(string.dropLast()) ?? 0) * 60
    } else if string.hasSuffix("h") {
        return (Double(string.dropLast()) ?? 0) * 3600
    } else if string.hasSuffix("d") {
        return (Double(string.dropLast()) ?? 0) * 86400
    } else if string.hasSuffix("s") {
        return Double(string.dropLast()) ?? 0
    } else if string.hasSuffix("ms") {
        return (Double(string.dropLast(2)) ?? 0) / 1000
    }
    return Double(string) ?? 0
}

while let line = readLine() {
    let cmp = line.components(separatedBy: " ")
    switch cmp[0] {
    case "reply":
        if cmp.count == 1 {
            print("\u{001B}[0;34mReply to the next request: \(joinReply)\u{001B}[0;0m")
            break
        }
        let valueSet = JoinReplyComplex(rawValue: cmp[1])
        if let valueSet = valueSet {
            joinReply = valueSet
            print("\u{001B}[0;35mJoin Reply set to \(valueSet)\u{001B}[0;0m")
        } else {
            print("\u{001B}[0;31mUnknown reply \(cmp[1])\u{001B}[0;0m")
        }
    case "partyid":
        if cmp.count == 1 {
            presence.party.id = nil
            presence.secrets.join = nil
            print("\u{001B}[0;35mAParty removed\u{001B}[0;0m")
        } else {
            presence.party.id = cmp[1]
            presence.secrets.join = cmp[1] + "-join"
            print("\u{001B}[0;35mAParty ID updated\u{001B}[0;0m")
        }
        rpc.setPresence(presence)
    case "canjoin":
        if cmp.count == 1 || cmp[1] == "no" || cmp[1] == "0" || cmp[1] == "false" {
            presence.secrets.join = nil
            print("\u{001B}[0;35mAsk to Join button disabled\u{001B}[0;0m")
        } else if let partyid = presence.party.id {
            presence.secrets.join = partyid + "-join"
            print("\u{001B}[0;35mAsk to Join button enabled\u{001B}[0;0m")
        } else {
            print("\u{001B}[0;31mParty ID required to enable Joining\u{001B}[0;0m")
        }
        rpc.setPresence(presence)
    case "details":
        presence.details = String(line.dropFirst(cmp[0].count + 1))
        rpc.setPresence(presence)
        print("\u{001B}[0;35mDetails updated\u{001B}[0;0m")
    case "state", "status":
        presence.state = String(line.dropFirst(cmp[0].count + 1))
        rpc.setPresence(presence)
        print("\u{001B}[0;35mState updated\u{001B}[0;0m")
    case "limg", "large-image":
        presence.assets.largeImage = String(line.dropFirst(cmp[0].count + 1))
        rpc.setPresence(presence)
        print("\u{001B}[0;35mImage updated\u{001B}[0;0m")
    case "ltxt", "large-text":
        presence.assets.largeText = String(line.dropFirst(cmp[0].count + 1))
        rpc.setPresence(presence)
        print("\u{001B}[0;35mImage tooltip updated\u{001B}[0;0m")
    case "party":
        presence.party.size = cmp.count == 1 ? nil : Int(cmp[1])
        presence.party.max = cmp.count == 1 ? nil : cmp.count == 2 ? presence.party.max : Int(cmp[2])
        rpc.setPresence(presence)
        if cmp.count == 1 {
            print("\u{001B}[0;35mDisabled party metadata\u{001B}[0;0m")
        } else {
            print("\u{001B}[0;35mParty metadata updated : \(presence.party.size ?? -1)/\(presence.party.max ?? -1)\u{001B}[0;0m")
        }
    case "start", "start-time", "start-timestamp":
        if cmp.count == 1 {
            presence.timestamps.start = nil
            print("\u{001B}[0;35mStart timestamp removed\u{001B}[0;0m")
        } else {
            presence.timestamps.start = Date(timeIntervalSinceNow: -timeSeconds(cmp[1]))
            print("\u{001B}[0;35mStart timestamp set to \(timeSeconds(cmp[1])) seconds ago\u{001B}[0;0m")
        }
        rpc.setPresence(presence)
    case "end", "end-time", "end-timestamp":
        if cmp.count == 1 {
            presence.timestamps.end = nil
            print("\u{001B}[0;35mEnd timestamp removed\u{001B}[0;0m")
        } else {
            presence.timestamps.end = Date(timeIntervalSinceNow: timeSeconds(cmp[1]))
            print("\u{001B}[0;35mEnd timestamp set to \(timeSeconds(cmp[1])) seconds from now\u{001B}[0;0m")
        }
        rpc.setPresence(presence)
    case "print", "dump", "debug":
        print(presence)
    case "restart":
        rpc.disconnect()
        rpc = buildRPC()
        rpc.connect()
    case "help":
        print("\u{001B}[0;32mCommands :\u{001B}[0;0m")
        print("\u{001B}[0;34mhelp\u{001B}[0;0m\n\tShows this help message")
        print("\u{001B}[0;34mdetails str\u{001B}[0;0m\n\tChanges the details to str (Under the app name)")
        print("\u{001B}[0;34mstate/status str\u{001B}[0;0m\n\tChanges the state to str (Under the details)")
        print("\u{001B}[0;34mlimg/large-image str\u{001B}[0;0m\n\tChanges the large image asset name to str")
        print("\u{001B}[0;34mltxt/large-text str\u{001B}[0;0m\n\tChanges the large image tooltip to str")
        print("\u{001B}[0;34mparty int int\u{001B}[0;0m\n\tChanges the current number of users in the party, and the maximum number of users who can join the party")
        print("\u{001B}[0;34mreply [alwaysYes / yesOnce / alwaysNo / noOnce / ask]\u{001B}[0;0m\n\tChanges the reply to the current and/or next join requests")
        print("\u{001B}[0;34mreply\u{001B}[0;0m\n\tShows the reply to the next join request")
        print("\u{001B}[0;34mstart\u{001B}[0;0m\n\tRemoves the start timestamp")
        print("\u{001B}[0;34mstart float\u{001B}[0;0m\n\tSets the start timestamp to float seconds before now (0 for now)")
        print("\u{001B}[0;34mend\u{001B}[0;0m\n\tRemoves the end timestamp")
        print("\u{001B}[0;34mend float\u{001B}[0;0m\n\tSets the end timestamp to float seconds from now")
        print("\u{001B}[0;34mpartyid\u{001B}[0;0m\n\tDeletes the party and disables Joining")
        print("\u{001B}[0;34mpartyid str\u{001B}[0;0m\n\tSets the Party ID to the given string, and enables Joining")
        print("\u{001B}[0;34mcanjoin [yes / no]\u{001B}[0;0m\n\tEnables or disables the Ask to Join button")
        print("\u{001B}[0;34mprint/dump/debug\u{001B}[0;0m\n\tDumps the current presence's debug description")
        print("\u{001B}[0;34mrestart\u{001B}[0;0m\n\tRestarts the RPC connection while keeping the current presence")
    default:
        print("Unknown command \(cmp[0])")
    }
}
