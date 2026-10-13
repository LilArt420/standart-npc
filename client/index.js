// standart-npc: shows the Attendance Check rewards the server really gives.
// The client draws the Attendance Check window from System/CheckAttendance.lub,
// which only has the mod's own list. Rewards chosen in the Settings… window are
// applied on the server (npc/when/enable_attendance/attendance_rewards.txt), so
// each time the window draws its days this asks that script for the running
// list and puts the right icon, name and amount on every day.

const STYLE = `
.attendance-item .item[data-snpc-icon] { background-image: var(--snpc-icon) !important; }
`;

// "id:amount,id:amount,..." -> [{ id, amount }], one per day
export function parseRewards(text) {
    return String(text || '').split(',').map(entry => {
        const [id, amount] = entry.split(':').map(Number);
        return id > 0 ? { id, amount: amount > 0 ? amount : 1 } : null;
    });
}

export default function init(parameters, api) {
    if (api?.version !== 1) throw new Error('standart-npc requires client API 1');

    let rewards = null;    // the running list, once the server has sent it
    let asking = null;     // the request in flight
    let failed = false;    // no answer on this connection: don't ask again
    const watched = new Map();  // component host -> { observer, style }

    api.on('connection', () => { rewards = null; asking = null; failed = false; });

    function ask() {
        if (rewards || failed) return Promise.resolve(rewards);
        if (!asking) {
            asking = api.server.request('snpcattendance', 'get')
                .then(text => { rewards = parseRewards(text); return rewards; })
                .catch(() => { failed = true; return null; })
                .finally(() => { asking = null; });
        }
        return asking;
    }

    async function redraw(list) {
        if (!list.children.length) return;
        const days = await ask();
        if (!days) return;
        for (let i = 0; i < days.length; i++) {
            const day = days[i];
            const slot = list.querySelector(`#attendance_day_${i} .item`);
            if (!day || !slot) continue;
            if (slot.dataset.snpcIcon === String(day.id) && slot.dataset.snpcAmount === String(day.amount)) continue;
            slot.dataset.snpcIcon = String(day.id);
            slot.dataset.snpcAmount = String(day.amount);
            const amount = slot.querySelector('.item-quantity');
            if (amount) amount.textContent = String(day.amount);
            const name = slot.querySelector('.name');
            if (name) name.textContent = api.items.get(day.id)?.name || `#${day.id}`;
            const url = await api.items.icon(day.id);
            if (url) slot.style.setProperty('--snpc-icon', `url("${url}")`);
        }
    }

    api.on('ui:append', component => {
        if (component.name !== 'CheckAttendance' || watched.has(component.host)) return;
        const list = component.root.querySelector('.days-list');
        if (!list) return;
        const style = document.createElement('style');
        style.textContent = STYLE;
        component.root.append(style);
        // The window empties and refills its days on every map load.
        const observer = new MutationObserver(() => redraw(list));
        observer.observe(list, { childList: true });
        watched.set(component.host, { observer, style });
        redraw(list);
    });
    const forget = host => {
        const w = watched.get(host);
        if (!w) return;
        w.observer.disconnect();
        w.style.remove();
        watched.delete(host);
    };
    api.on('ui:remove', ({ host }) => forget(host));
    api.cleanup(() => { for (const host of [...watched.keys()]) forget(host); });
}
