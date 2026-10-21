import EbbCore
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(Store.self) private var store
    @Environment(BackupService.self) private var backup
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @State private var pickFolder = false
    @State private var pickRestore = false
    @State private var restoreCandidate: URL?
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Время для тревоги") {
                    Picker("Час", selection: worryHour) {
                        ForEach(0..<24, id: \.self) { h in
                            Text(String(format: "%02d:00", h)).tag(h)
                        }
                    }
                    Text("В этот час на «Сейчас» появятся отложенные мысли.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Toggle("Напоминать о времени для тревоги", isOn: worryReminder)
                    Toggle("Напоминать о плане дня", isOn: planReminders)
                } header: {
                    Text("Напоминания")
                } footer: {
                    Text("Выключены по умолчанию. Уведомления появятся в следующей версии; под LiveContainer они могут не приходить.")
                }

                Section {
                    if let folder = backup.folderURL {
                        LabeledContent("Папка", value: folder.lastPathComponent)
                        LabeledContent("Последняя копия", value: backup.lastBackupAt?.formatted(date: .abbreviated, time: .shortened) ?? "ещё не было")
                        if let err = backup.lastError {
                            Text(err).font(.footnote).foregroundStyle(.red)
                        }
                        Button("Сделать копию сейчас") { backupNow() }
                        Button("Выбрать другую папку") { pickFolder = true }
                    } else {
                        Button("Выбрать папку в «Файлах»") { pickFolder = true }
                    }
                    Button("Восстановить из файла", role: .destructive) { pickRestore = true }
                } header: {
                    Text("Резервная копия")
                } footer: {
                    Text("Копия ebb-backup.json обновляется после каждого изменения и переживает переустановку приложения.")
                }

                Section("Экспорт для ИИ") {
                    Text("Появится в следующей версии.")
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background(scheme))
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .fileImporter(isPresented: $pickFolder, allowedContentTypes: [.folder]) { result in
                if case .success(let url) = result {
                    do {
                        try backup.setFolder(url)
                        try backup.backupNow()
                    } catch {
                        message = "Не удалось сохранить копию: \(error.localizedDescription)"
                    }
                }
            }
            .fileImporter(isPresented: $pickRestore, allowedContentTypes: [.json]) { result in
                if case .success(let url) = result { restoreCandidate = url }
            }
            .confirmationDialog("Заменить все данные содержимым файла?", isPresented: Binding(get: { restoreCandidate != nil }, set: { if !$0 { restoreCandidate = nil } }), titleVisibility: .visible) {
                Button("Заменить", role: .destructive) { restore() }
                Button("Отмена", role: .cancel) { restoreCandidate = nil }
            } message: {
                Text("Текущие записи будут удалены. Отменить это нельзя.")
            }
            .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("Ок") { message = nil }
            }
        }
        .tint(Theme.accent(scheme))
    }

    // MARK: - Привязки

    private var worryHour: Binding<Int> {
        Binding(get: { store.settings.worryTimeHour }, set: { h in
            var s = store.settings
            s.worryTimeHour = h
            store.save(settings: s)
        })
    }

    private var worryReminder: Binding<Bool> {
        Binding(get: { store.settings.worryTimeReminder }, set: { v in
            var s = store.settings
            s.worryTimeReminder = v
            store.save(settings: s)
        })
    }

    private var planReminders: Binding<Bool> {
        Binding(get: { store.settings.planReminders }, set: { v in
            var s = store.settings
            s.planReminders = v
            store.save(settings: s)
        })
    }

    // MARK: - Действия

    private func backupNow() {
        do {
            try backup.backupNow()
            message = "Копия сохранена."
        } catch {
            message = "Не удалось сохранить копию: \(error.localizedDescription)"
        }
    }

    private func restore() {
        guard let url = restoreCandidate else { return }
        restoreCandidate = nil
        do {
            try backup.restore(from: url)
            message = "Данные восстановлены."
        } catch {
            message = "Файл не подошёл: \(error.localizedDescription). Данные не тронуты."
        }
    }
}
