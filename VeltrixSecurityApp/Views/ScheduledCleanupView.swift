import SwiftUI

struct ScheduledCleanupView: View {
    @State private var manager = ScheduledCleanupManager.shared
    @State private var draftSettings = ScheduledCleanupSettings()
    @State private var isSaving = false
    @State private var showSavedBanner = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                enableToggleCard
                if draftSettings.isEnabled {
                    frequencyCard
                    timeCard
                    targetCard
                }
                if let desc = manager.lastScheduledDescription {
                    activeScheduleCard(desc)
                }
                if let err = manager.lastError {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
                saveButton
            }
            .padding(30)
            .frame(maxWidth: 720, alignment: .leading)
        }
        .onAppear { draftSettings = manager.settings }
        .overlay(alignment: .top) {
            if showSavedBanner {
                savedBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
    }

    // MARK: - Sub-views

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Limpieza Programada")
                .font(.largeTitle.weight(.semibold))
            Text("Veltrix Security puede ejecutar limpiezas automáticas según el horario que elijas. Recibirás una notificación cuando finalice.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 640, alignment: .leading)
        }
    }

    private var enableToggleCard: some View {
        HStack {
            Label("Activar limpieza automática", systemImage: "clock.arrow.circlepath")
                .font(.headline)
            Spacer()
            Toggle("", isOn: $draftSettings.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.primary.opacity(0.06)))
    }

    private var frequencyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Frecuencia").font(.headline)
            HStack(spacing: 12) {
                ForEach(CleanupFrequency.allCases) { freq in
                    frequencyOption(freq)
                }
            }

            if draftSettings.frequency == .weekly {
                Picker("Día de la semana", selection: $draftSettings.weekday) {
                    ForEach(Weekday.allCases) { day in
                        Text(day.displayName).tag(day)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            if draftSettings.frequency == .monthly {
                HStack {
                    Text("Día del mes:")
                        .foregroundStyle(.secondary)
                    Stepper("\(draftSettings.dayOfMonth)", value: $draftSettings.dayOfMonth, in: 1...28)
                        .fixedSize()
                }
            }
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.primary.opacity(0.06)))
    }

    private var timeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hora de la limpieza").font(.headline)
            HStack(spacing: 12) {
                Stepper(value: $draftSettings.hour, in: 0...23) {
                    Label(String(format: "%02d h", draftSettings.hour), systemImage: "clock")
                }
                .fixedSize()
                Stepper(value: $draftSettings.minute, in: 0...59, step: 5) {
                    Text(String(format: "%02d min", draftSettings.minute))
                        .foregroundStyle(.secondary)
                }
                .fixedSize()
            }
            Text("La limpieza se iniciará aproximadamente a las \(String(format: "%02d:%02d", draftSettings.hour, draftSettings.minute)).")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.primary.opacity(0.06)))
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Qué limpiar automáticamente").font(.headline)
            Toggle("Cachés de usuario (~/Library/Caches)", isOn: $draftSettings.cleanCaches)
            Toggle("Buscar archivos grandes (>100 MB)", isOn: $draftSettings.cleanLargeFiles)
            Toggle("Análisis de amenazas y agentes de inicio", isOn: $draftSettings.scanThreats)
        }
        .padding(18)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.primary.opacity(0.06)))
    }

    private func activeScheduleCard(_ description: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Limpieza programada activa")
                    .font(.headline)
                Text(description)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.green.opacity(0.2)))
    }

    private var saveButton: some View {
        HStack(spacing: 14) {
            Button {
                saveChanges()
            } label: {
                Label(isSaving ? "Guardando…" : "Guardar cambios", systemImage: "checkmark")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)

            if manager.settings.isEnabled {
                Button(role: .destructive) {
                    Task {
                        await manager.disable()
                        draftSettings = manager.settings
                    }
                } label: {
                    Label("Desactivar programación", systemImage: "xmark.circle")
                }
            }
        }
    }

    private var savedBanner: some View {
        Label("Programación guardada correctamente", systemImage: "checkmark.circle.fill")
            .font(.callout.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.green, in: RoundedRectangle(cornerRadius: 10))
            .padding(.top, 16)
    }

    // MARK: - Helpers

    private func frequencyOption(_ freq: CleanupFrequency) -> some View {
        let isSelected = draftSettings.frequency == freq
        return Button {
            draftSettings.frequency = freq
        } label: {
            VStack(spacing: 6) {
                Image(systemName: freq.systemSymbol)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .orange)
                Text(freq.displayName)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.orange : Color(nsColor: .controlBackgroundColor),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.orange : .primary.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }

    private func saveChanges() {
        isSaving = true
        Task {
            await manager.save(settings: draftSettings)
            isSaving = false
            withAnimation(.spring(duration: 0.3)) { showSavedBanner = true }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.3)) { showSavedBanner = false }
        }
    }
}
