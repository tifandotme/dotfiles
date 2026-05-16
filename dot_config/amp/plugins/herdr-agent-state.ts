import type { PluginAPI } from '@ampcode/plugin'
import { connect } from 'node:net'

const SOURCE = 'amp:herdr-agent-state'
const AGENT = 'amp'

type HerdrState = 'idle' | 'working' | 'blocked' | 'unknown'

interface HerdrRequest {
	id: string
	method: 'pane.report_agent'
	params: {
		pane_id: string
		source: string
		agent: string
		state: HerdrState
		message?: string
	}
}

export default function (amp: PluginAPI) {
	amp.logger.log('herdr agent-state plugin initialized')

	const report = async (state: HerdrState, message?: string) => {
		try {
			await reportToHerdr(state, message)
			amp.logger.log(`reported ${state} to herdr${message ? `: ${message}` : ''}`)
		} catch (error) {
			amp.logger.error(`failed to report ${state} to herdr: ${errorMessage(error)}`)
		}
	}

	amp.on('session.start', async (event) => {
		await report('idle', `session ${event.thread.id} started`)
	})

	amp.on('agent.start', async (event) => {
		await report('working', `thread ${event.thread.id} agent turn started`)
		return {}
	})

	amp.on('tool.call', async (event) => {
		await report('working', `thread ${event.thread.id} calling ${event.tool}`)
		return { action: 'allow' }
	})

	amp.on('tool.result', async (event) => {
		await report('working', `thread ${event.thread.id} ${event.tool} ${event.status}`)
	})

	amp.on('agent.end', async (event) => {
		await report('idle', `thread ${event.thread.id} agent turn ${event.status}`)
	})
}

async function reportToHerdr(state: HerdrState, message?: string): Promise<void> {
	const socketPath = process.env.HERDR_SOCKET_PATH
	const paneId = process.env.HERDR_PANE_ID

	if (!socketPath) {
		throw new Error('HERDR_SOCKET_PATH is not set')
	}
	if (!paneId) {
		throw new Error('HERDR_PANE_ID is not set')
	}

	const request: HerdrRequest = {
		id: `amp-herdr-${Date.now()}-${Math.random().toString(16).slice(2)}`,
		method: 'pane.report_agent',
		params: {
			pane_id: paneId,
			source: SOURCE,
			agent: AGENT,
			state,
			message,
		},
	}

	const response = await sendJsonLine(socketPath, request)
	if (response.error) {
		throw new Error(response.error.message ?? JSON.stringify(response.error))
	}
}

async function sendJsonLine(socketPath: string, request: HerdrRequest): Promise<any> {
	return await new Promise((resolve, reject) => {
		const socket = connect(socketPath)
		let buffer = ''
		let settled = false

		const timeout = setTimeout(() => {
			finish(new Error('timed out waiting for herdr socket response'))
		}, 2_000)

		const finish = (error?: Error, value?: unknown) => {
			if (settled) {
				return
			}
			settled = true
			clearTimeout(timeout)
			socket.destroy()
			if (error) {
				reject(error)
			} else {
				resolve(value)
			}
		}

		socket.on('connect', () => {
			socket.write(`${JSON.stringify(request)}\n`)
		})

		socket.on('data', (chunk) => {
			buffer += chunk.toString('utf8')
			const newline = buffer.indexOf('\n')
			if (newline === -1) {
				return
			}

			const line = buffer.slice(0, newline).trim()
			if (!line) {
				return
			}

			try {
				finish(undefined, JSON.parse(line))
			} catch (error) {
				finish(new Error(`invalid herdr socket response: ${errorMessage(error)}`))
			}
		})

		socket.on('error', (error) => {
			finish(error)
		})

		socket.on('end', () => {
			if (!settled) {
				finish(new Error('herdr socket closed before responding'))
			}
		})
	})
}

function errorMessage(error: unknown): string {
	return error instanceof Error ? error.message : String(error)
}
